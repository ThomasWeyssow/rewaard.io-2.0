-- First, update nominations to remove cycle_id for non-completed cycles
UPDATE nominations
SET cycle_id = NULL
WHERE cycle_id IN (
  SELECT id 
  FROM nomination_cycles 
  WHERE status IN ('next', 'ongoing')
);

-- Then update nomination_history to remove cycle_id for non-completed cycles
UPDATE nomination_history
SET cycle_id = NULL
WHERE cycle_id IN (
  SELECT id 
  FROM nomination_cycles 
  WHERE status IN ('next', 'ongoing')
);

-- Now we can safely update settings
UPDATE settings
SET 
  next_cycle_id = NULL,
  ongoing_cycle_id = NULL
WHERE next_cycle_id IN (SELECT id FROM nomination_cycles WHERE status IN ('next', 'ongoing'))
   OR ongoing_cycle_id IN (SELECT id FROM nomination_cycles WHERE status IN ('next', 'ongoing'));

-- Finally delete non-completed cycles
DELETE FROM nomination_cycles 
WHERE status IN ('next', 'ongoing');

-- Drop existing functions and triggers
DROP FUNCTION IF EXISTS handle_nomination_cycles CASCADE;
DROP FUNCTION IF EXISTS check_and_update_nomination_cycles CASCADE;

-- Create updated function to handle nomination cycles
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate next_nomination_end_date if it's not provided
  IF NEW.next_nomination_start_date IS NOT NULL AND NEW.next_nomination_end_date IS NULL THEN
    -- Set time to midnight (00:00:00) Paris time
    NEW.next_nomination_start_date := date_trunc('day', NEW.next_nomination_start_date)::timestamptz + interval '23 hours';
    
    IF NEW.next_nomination_period = 'monthly' THEN
      -- End date is last day of the month at 23:59:59 Paris time
      NEW.next_nomination_end_date := date_trunc('month', NEW.next_nomination_start_date) + interval '1 month' - interval '1 second';
    ELSE -- 'bi-monthly'
      -- End date is last day of next month at 23:59:59 Paris time
      NEW.next_nomination_end_date := date_trunc('month', NEW.next_nomination_start_date) + interval '2 months' - interval '1 second';
    END IF;
  END IF;

  -- Check if we need to transition to a new cycle
  IF TG_OP = 'UPDATE' AND 
     NEW.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     NEW.ongoing_nomination_start_date IS NULL THEN
    -- Move next cycle to ongoing
    NEW.ongoing_nomination_start_date := NEW.next_nomination_start_date;
    NEW.ongoing_nomination_end_date := NEW.next_nomination_end_date;
    NEW.ongoing_nomination_area_id := NEW.next_nomination_area_id;
    NEW.ongoing_nomination_period := NEW.next_nomination_period;

    -- Set next cycle to start at midnight the day after ongoing cycle ends
    NEW.next_nomination_start_date := date_trunc('day', NEW.ongoing_nomination_end_date + interval '1 day')::timestamptz + interval '23 hours';
    NEW.next_nomination_area_id := NULL;
    NEW.next_nomination_period := NULL;
    NEW.next_nomination_end_date := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER handle_nomination_cycles_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION handle_nomination_cycles();

-- Create function to check and update nomination cycles
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  completed_cycle_id uuid;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
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
      completed_cycle_id,
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