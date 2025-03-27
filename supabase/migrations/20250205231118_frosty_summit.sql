-- Mettre à jour la fonction check_and_update_nomination_cycles pour gérer les cycles vides
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  nominations_to_archive integer;
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
      -- Create completed cycle entry even if there are no nominations
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
        DELETE FROM nominations;

        RAISE NOTICE 'Archived % nominations to cycle %', nominations_to_archive, completed_cycle_id;
      ELSE
        RAISE NOTICE 'No nominations to archive for cycle %', completed_cycle_id;
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

-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create new policies that handle empty cycles
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only allow nominations during an active cycle
    EXISTS (
      SELECT 1 
      FROM settings s 
      WHERE s.ongoing_nomination_start_date IS NOT NULL
      AND s.ongoing_nomination_end_date > CURRENT_TIMESTAMP
    )
    AND
    -- Ensure the voter is the authenticated user
    voter_id = auth.uid()
    AND
    -- Ensure one nomination per voter per cycle
    NOT EXISTS (
      SELECT 1 
      FROM nominations n2 
      WHERE n2.voter_id = auth.uid()
    )
  );

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (
    -- Only allow users to delete their own nominations
    voter_id = auth.uid()
    AND
    -- Only during an active cycle
    EXISTS (
      SELECT 1 
      FROM settings s 
      WHERE s.ongoing_nomination_start_date IS NOT NULL
      AND s.ongoing_nomination_end_date > CURRENT_TIMESTAMP
    )
  );

-- Create empty cycle if none exists
INSERT INTO nomination_cycles (
  start_date,
  end_date,
  period,
  status
)
SELECT 
  CURRENT_TIMESTAMP - interval '1 month',
  CURRENT_TIMESTAMP - interval '1 day',
  'monthly',
  'completed'
WHERE NOT EXISTS (
  SELECT 1 
  FROM nomination_cycles 
  WHERE status = 'completed'
);

-- Verify the current state
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  EXISTS (
    SELECT 1 
    FROM settings 
    WHERE ongoing_nomination_start_date IS NOT NULL
    AND ongoing_nomination_end_date > CURRENT_TIMESTAMP
  ) as active_cycle_exists,
  (
    SELECT ongoing_cycle_id 
    FROM settings 
    LIMIT 1
  ) as ongoing_cycle_id;