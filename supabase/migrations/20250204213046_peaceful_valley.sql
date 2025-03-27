-- Drop existing function
DROP FUNCTION IF EXISTS check_and_update_nomination_cycles CASCADE;

-- Create updated function to handle nomination cycles
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    -- Save completed cycle to nomination_cycles
    WITH completed_cycle AS (
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
      RETURNING id
    )
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
      (SELECT id FROM completed_cycle),
      settings_record.ongoing_nomination_start_date,
      settings_record.ongoing_nomination_end_date,
      n.voter_id,
      n.nominee_id,
      n.selected_areas,
      n.justification,
      n.remarks,
      settings_record.ongoing_nomination_area_id
    FROM nominations n
    WHERE 
      n.nomination_cycle_start = settings_record.ongoing_nomination_start_date AND
      n.nomination_cycle_end = settings_record.ongoing_nomination_end_date;

    -- Delete archived nominations
    DELETE FROM nominations
    WHERE 
      nomination_cycle_start = settings_record.ongoing_nomination_start_date AND
      nomination_cycle_end = settings_record.ongoing_nomination_end_date;

    -- Clear ongoing cycle
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

    RAISE NOTICE 'Completed cycle archived at %', CURRENT_TIMESTAMP;
  END IF;

  -- Check if we need to start a new cycle
  IF settings_record.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     settings_record.ongoing_nomination_start_date IS NULL THEN
    -- Move next cycle to ongoing
    UPDATE settings
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      -- Set next cycle to start at midnight Paris time the day after ongoing cycle ends
      next_nomination_start_date = date_trunc('day', next_nomination_end_date + interval '1 day')::timestamptz + interval '23 hours',
      next_nomination_area_id = NULL,
      next_nomination_period = NULL,
      next_nomination_end_date = NULL
    WHERE id = settings_record.id;

    RAISE NOTICE 'Started new nomination cycle at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Execute the function to check current cycles
SELECT check_and_update_nomination_cycles();

-- Verify the current state
SELECT 
  'Current state:' as info,
  to_char(next_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_start,
  to_char(next_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_end,
  next_nomination_period,
  next_nomination_area_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  ongoing_nomination_period,
  ongoing_nomination_area_id
FROM settings;