-- Create nomination_validations_history table if it doesn't exist
CREATE TABLE IF NOT EXISTS nomination_validations_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id uuid REFERENCES nomination_cycles(id) ON DELETE CASCADE,
  validator_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  nominee_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS if not already enabled
ALTER TABLE nomination_validations_history ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "nomination_validations_history_select" ON nomination_validations_history;

-- Create policy for reading validation history
CREATE POLICY "nomination_validations_history_select"
  ON nomination_validations_history FOR SELECT
  TO authenticated
  USING (true);

-- Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_nomination_validations_history_cycle 
ON nomination_validations_history(cycle_id);

-- Update check_and_update_nomination_cycles function to handle validation archiving
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  nominations_to_archive integer;
  validations_to_archive integer;
  completed_cycle_id uuid;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    -- Only archive if there is an ongoing cycle
    IF settings_record.ongoing_nomination_start_date IS NOT NULL AND 
       settings_record.ongoing_nomination_end_date IS NOT NULL THEN
      -- Create completed cycle entry
      INSERT INTO nomination_cycles (
        start_date,
        end_date,
        period,
        nomination_area_id,
        status
      )
      VALUES (
        settings_record.ongoing_nomination_start_date,
        settings_record.ongoing_nomination_end_date,
        settings_record.ongoing_nomination_period,
        settings_record.ongoing_nomination_area_id,
        'completed'
      )
      RETURNING id INTO completed_cycle_id;

      -- Get count of nominations to archive
      SELECT COUNT(*) INTO nominations_to_archive FROM nominations;

      -- Get count of validations to archive
      SELECT COUNT(*) INTO validations_to_archive FROM nomination_validations;

      -- Move nominations to history if any exist
      IF nominations_to_archive > 0 THEN
        INSERT INTO nomination_history (
          cycle_id,
          voter_id,
          nominee_id,
          selected_areas,
          justification,
          remarks,
          nomination_area_id
        )
        SELECT 
          completed_cycle_id,
          n.voter_id,
          n.nominee_id,
          n.selected_areas,
          n.justification,
          n.remarks,
          settings_record.ongoing_nomination_area_id
        FROM nominations n;

        -- Delete archived nominations
        TRUNCATE nominations;

        RAISE NOTICE 'Archived % nominations to cycle %', nominations_to_archive, completed_cycle_id;
      END IF;

      -- Move validations to history if any exist
      IF validations_to_archive > 0 THEN
        INSERT INTO nomination_validations_history (
          cycle_id,
          validator_id,
          nominee_id
        )
        SELECT 
          completed_cycle_id,
          nv.validator_id,
          nv.nominee_id
        FROM nomination_validations nv;

        -- Delete archived validations
        TRUNCATE nomination_validations;

        RAISE NOTICE 'Archived % validations to cycle %', validations_to_archive, completed_cycle_id;
      END IF;
    END IF;

    -- Clear ongoing cycle
    UPDATE settings
    SET
      ongoing_nomination_start_date = NULL,
      ongoing_nomination_end_date = NULL,
      ongoing_nomination_area_id = NULL,
      ongoing_nomination_period = NULL,
      ongoing_cycle_id = NULL
    WHERE id = settings_record.id;
    
    -- Refresh settings record
    SELECT * INTO settings_record
    FROM settings
    LIMIT 1;

    RAISE NOTICE 'Completed cycle archived at %', CURRENT_TIMESTAMP;
  END IF;

  -- Check if we need to start a new cycle
  IF settings_record.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     settings_record.ongoing_nomination_start_date IS NULL THEN
    -- Generate new cycle_id
    WITH new_cycle AS (
      SELECT gen_random_uuid() as id
    )
    -- Move next cycle to ongoing with new cycle_id
    UPDATE settings s
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      ongoing_cycle_id = nc.id,
      -- Set next cycle to start at midnight Paris time the day after ongoing cycle ends
      next_nomination_start_date = date_trunc('day', next_nomination_end_date + interval '1 day')::timestamptz + interval '23 hours',
      next_nomination_area_id = NULL,
      next_nomination_period = 'monthly',
      next_nomination_end_date = NULL
    FROM new_cycle nc
    WHERE s.id = settings_record.id;

    RAISE NOTICE 'Started new nomination cycle at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Verify the current state
SELECT 
  'État actuel:' as section,
  (SELECT COUNT(*) FROM nominations) as nominations_actives,
  (SELECT COUNT(*) FROM nomination_history) as nominations_archivees,
  (SELECT COUNT(*) FROM nomination_validations) as validations_actives,
  (SELECT COUNT(*) FROM nomination_validations_history) as validations_archivees,
  (SELECT COUNT(*) FROM nomination_cycles WHERE status = 'completed') as cycles_completes;