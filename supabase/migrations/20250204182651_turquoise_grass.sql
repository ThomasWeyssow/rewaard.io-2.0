-- Create nomination cycles table
CREATE TABLE nomination_cycles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL,
  period text NOT NULL CHECK (period IN ('monthly', 'bi-monthly')),
  nomination_area_id uuid REFERENCES nomination_areas(id),
  status text NOT NULL CHECK (status IN ('next', 'ongoing', 'completed')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE nomination_cycles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can read nomination cycles"
  ON nomination_cycles FOR SELECT
  TO authenticated
  USING (true);

-- Add cycle_id to nominations table
ALTER TABLE nominations
ADD COLUMN cycle_id uuid REFERENCES nomination_cycles(id);

-- Add cycle_id to nomination_history table
ALTER TABLE nomination_history
ADD COLUMN cycle_id uuid REFERENCES nomination_cycles(id);

-- Add indexes for better performance
CREATE INDEX idx_nomination_cycles_status ON nomination_cycles(status);
CREATE INDEX idx_nominations_cycle_id ON nominations(cycle_id);
CREATE INDEX idx_nomination_history_cycle_id ON nomination_history(cycle_id);

-- Update check_and_update_nomination_cycles function to use cycles table
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  next_cycle_id uuid;
  ongoing_cycle_id uuid;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    -- Get ongoing cycle ID
    SELECT id INTO ongoing_cycle_id
    FROM nomination_cycles
    WHERE status = 'ongoing'
    LIMIT 1;

    IF ongoing_cycle_id IS NOT NULL THEN
      -- Move current nominations to history
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
        ongoing_cycle_id,
        settings_record.ongoing_nomination_start_date,
        settings_record.ongoing_nomination_end_date,
        voter_id,
        nominee_id,
        selected_areas,
        justification,
        remarks,
        settings_record.ongoing_nomination_area_id
      FROM nominations
      WHERE cycle_id = ongoing_cycle_id;

      -- Update cycle status to completed
      UPDATE nomination_cycles
      SET status = 'completed'
      WHERE id = ongoing_cycle_id;

      -- Delete old nominations
      DELETE FROM nominations
      WHERE cycle_id = ongoing_cycle_id;
    END IF;

    -- Clear ongoing cycle in settings
    UPDATE settings
    SET
      ongoing_nomination_start_date = NULL,
      ongoing_nomination_end_date = NULL,
      ongoing_nomination_area_id = NULL,
      ongoing_nomination_period = NULL
    WHERE id = settings_record.id;
    
    -- Refresh settings record
    SELECT * INTO settings_record
    FROM settings
    LIMIT 1;
  END IF;

  -- Check if we need to start a new cycle
  IF settings_record.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     settings_record.ongoing_nomination_start_date IS NULL THEN
    
    -- Get next cycle ID
    SELECT id INTO next_cycle_id
    FROM nomination_cycles
    WHERE status = 'next'
    LIMIT 1;

    -- Move next cycle to ongoing
    UPDATE nomination_cycles
    SET 
      status = 'ongoing',
      updated_at = now()
    WHERE id = next_cycle_id;

    -- Calculate end date for new next cycle
    WITH next_cycle_dates AS (
      SELECT
        date_trunc('day', settings_record.next_nomination_end_date + interval '1 day') + interval '23 hours' as start_date,
        CASE 
          WHEN settings_record.next_nomination_period = 'monthly' THEN
            date_trunc('day', settings_record.next_nomination_end_date + interval '1 month') + interval '22 hours' + interval '59 minutes' + interval '59 seconds'
          ELSE
            date_trunc('day', settings_record.next_nomination_end_date + interval '2 months') + interval '22 hours' + interval '59 minutes' + interval '59 seconds'
        END as end_date
    )
    -- Create new next cycle with calculated dates
    INSERT INTO nomination_cycles (
      start_date,
      end_date,
      period,
      status
    )
    SELECT
      start_date,
      end_date,
      settings_record.next_nomination_period,
      'next'
    FROM next_cycle_dates;

    -- Update settings
    UPDATE settings
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      -- Set next cycle to start at 23:00:00 UTC the day after ongoing cycle ends
      next_nomination_start_date = date_trunc('day', next_nomination_end_date + interval '1 day') + interval '23 hours',
      next_nomination_area_id = NULL,
      next_nomination_period = NULL,
      next_nomination_end_date = NULL
    WHERE id = settings_record.id;

    RAISE NOTICE 'Nomination cycle updated at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating timestamps
CREATE TRIGGER update_nomination_cycles_updated_at
  BEFORE UPDATE ON nomination_cycles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Create initial cycles from current settings with proper end dates
WITH cycle_dates AS (
  SELECT
    'next' as status,
    next_nomination_start_date as start_date,
    next_nomination_end_date as end_date,
    next_nomination_period as period,
    next_nomination_area_id as area_id
  FROM settings
  WHERE next_nomination_start_date IS NOT NULL
  UNION ALL
  SELECT
    'ongoing' as status,
    ongoing_nomination_start_date as start_date,
    ongoing_nomination_end_date as end_date,
    ongoing_nomination_period as period,
    ongoing_nomination_area_id as area_id
  FROM settings
  WHERE ongoing_nomination_start_date IS NOT NULL
)
INSERT INTO nomination_cycles (
  start_date,
  end_date,
  period,
  nomination_area_id,
  status
)
SELECT
  start_date,
  COALESCE(
    end_date,
    CASE 
      WHEN period = 'monthly' THEN
        date_trunc('day', start_date + interval '1 month') + interval '22 hours' + interval '59 minutes' + interval '59 seconds'
      ELSE
        date_trunc('day', start_date + interval '2 months') + interval '22 hours' + interval '59 minutes' + interval '59 seconds'
    END
  ),
  COALESCE(period, 'monthly'),
  area_id,
  status
FROM cycle_dates
WHERE start_date IS NOT NULL;