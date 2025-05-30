-- Update the cron function to properly handle cycle completion
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  completed_cycle_id uuid;
  nominations_to_archive integer;
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

      -- Move nominations to history if any exist
      IF nominations_to_archive > 0 THEN
        -- Create temporary table to store nominations to move
        CREATE TEMP TABLE nominations_to_move AS
        SELECT * FROM nominations;

        -- Move nominations to history
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
        FROM nominations_to_move n;

        -- Delete archived nominations
        TRUNCATE nominations;

        -- Drop temporary table
        DROP TABLE nominations_to_move;

        RAISE NOTICE 'Archived % nominations to cycle %', nominations_to_archive, completed_cycle_id;
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

      RAISE NOTICE 'Completed cycle archived at %', CURRENT_TIMESTAMP;
    END IF;
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

-- Drop existing cron job if it exists
SELECT cron.unschedule('check-nomination-cycles');

-- Schedule the cron job to run every minute for testing
SELECT cron.schedule(
  'check-nomination-cycles',
  '* * * * *',  -- Run every minute
  'SELECT check_and_update_nomination_cycles()'
);

-- Execute the function immediately
SELECT check_and_update_nomination_cycles();

-- Verify the current state
SELECT 
  'État actuel:' as section,
  (SELECT COUNT(*) FROM nominations) as nominations_actives,
  (SELECT COUNT(*) FROM nomination_history) as nominations_archivees,
  (SELECT COUNT(*) FROM nomination_cycles WHERE status = 'completed') as cycles_completes,
  (
    SELECT json_build_object(
      'start', to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS'),
      'end', to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS')
    )
    FROM settings
    LIMIT 1
  ) as cycle_en_cours;