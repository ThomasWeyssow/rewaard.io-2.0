-- Drop existing function and trigger
DROP FUNCTION IF EXISTS handle_nomination_cycles CASCADE;
DROP TRIGGER IF EXISTS handle_nomination_cycles_trigger ON settings;

-- Drop existing cycle information columns from settings
ALTER TABLE settings
DROP COLUMN IF EXISTS next_nomination_start_date,
DROP COLUMN IF EXISTS next_nomination_end_date,
DROP COLUMN IF EXISTS next_nomination_period,
DROP COLUMN IF EXISTS next_nomination_area_id,
DROP COLUMN IF EXISTS ongoing_nomination_start_date,
DROP COLUMN IF EXISTS ongoing_nomination_end_date,
DROP COLUMN IF EXISTS ongoing_nomination_period,
DROP COLUMN IF EXISTS ongoing_nomination_area_id;

-- Add cycle reference columns to settings
ALTER TABLE settings
ADD COLUMN next_cycle_id uuid REFERENCES nomination_cycles(id),
ADD COLUMN ongoing_cycle_id uuid REFERENCES nomination_cycles(id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_settings_next_cycle 
ON settings(next_cycle_id);

CREATE INDEX IF NOT EXISTS idx_settings_ongoing_cycle 
ON settings(ongoing_cycle_id);

-- Create initial cycle if needed
WITH new_cycle AS (
  INSERT INTO nomination_cycles (
    start_date,
    end_date,
    period,
    status
  )
  SELECT
    date_trunc('day', CURRENT_TIMESTAMP + interval '1 day') + interval '23 hours',
    date_trunc('day', CURRENT_TIMESTAMP + interval '1 month') + interval '22 hours' + interval '59 minutes' + interval '59 seconds',
    'monthly',
    'next'
  WHERE NOT EXISTS (
    SELECT 1 FROM nomination_cycles WHERE status = 'next'
  )
  RETURNING id
)
-- Update settings with new cycle reference
UPDATE settings
SET next_cycle_id = (SELECT id FROM new_cycle)
WHERE next_cycle_id IS NULL;

-- Create function to check and update nomination cycles
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  ongoing_cycle RECORD;
  next_cycle RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Get ongoing cycle if exists
  SELECT * INTO ongoing_cycle
  FROM nomination_cycles
  WHERE id = settings_record.ongoing_cycle_id;

  -- Check if ongoing cycle is finished
  IF ongoing_cycle.id IS NOT NULL AND ongoing_cycle.end_date < CURRENT_TIMESTAMP THEN
    -- Move nominations to history
    INSERT INTO nomination_history (
      cycle_id,
      cycle_start_date,
      cycle_end_date,
      voter_id,
      nominee_id,
      selected_areas,
      justification,
      remarks,
      nomination_area_id
    )
    SELECT 
      ongoing_cycle.id,
      ongoing_cycle.start_date,
      ongoing_cycle.end_date,
      n.voter_id,
      n.nominee_id,
      n.selected_areas,
      n.justification,
      n.remarks,
      ongoing_cycle.nomination_area_id
    FROM nominations n
    WHERE n.cycle_id = ongoing_cycle.id;

    -- Delete archived nominations
    DELETE FROM nominations
    WHERE cycle_id = ongoing_cycle.id;

    -- Update cycle status
    UPDATE nomination_cycles
    SET status = 'completed'
    WHERE id = ongoing_cycle.id;

    -- Clear ongoing cycle reference
    UPDATE settings
    SET ongoing_cycle_id = NULL
    WHERE id = settings_record.id;
    
    -- Refresh settings record
    SELECT * INTO settings_record
    FROM settings
    LIMIT 1;
  END IF;

  -- Get next cycle if exists
  SELECT * INTO next_cycle
  FROM nomination_cycles
  WHERE id = settings_record.next_cycle_id;

  -- Check if we need to start a new cycle
  IF next_cycle.id IS NOT NULL AND next_cycle.start_date <= CURRENT_TIMESTAMP AND 
     (ongoing_cycle.id IS NULL OR ongoing_cycle.end_date < CURRENT_TIMESTAMP) THEN
    -- Move next cycle to ongoing
    UPDATE nomination_cycles
    SET status = 'ongoing'
    WHERE id = next_cycle.id;

    -- Create new next cycle and store its ID
    WITH new_cycle AS (
      INSERT INTO nomination_cycles (
        start_date,
        end_date,
        period,
        status
      )
      VALUES (
        date_trunc('day', next_cycle.end_date + interval '1 day') + interval '23 hours',
        CASE 
          WHEN next_cycle.period = 'monthly' THEN
            date_trunc('day', next_cycle.end_date + interval '1 month') + interval '22 hours' + interval '59 minutes' + interval '59 seconds'
          ELSE
            date_trunc('day', next_cycle.end_date + interval '2 months') + interval '22 hours' + interval '59 minutes' + interval '59 seconds'
        END,
        COALESCE(next_cycle.period, 'monthly'),
        'next'
      )
      RETURNING id
    )
    -- Update settings with new cycle references
    UPDATE settings
    SET
      ongoing_cycle_id = next_cycle.id,
      next_cycle_id = (SELECT id FROM new_cycle LIMIT 1)
    WHERE id = settings_record.id;

    RAISE NOTICE 'Started new nomination cycle at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;