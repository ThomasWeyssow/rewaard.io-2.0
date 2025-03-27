-- Drop existing function
DROP FUNCTION IF EXISTS handle_nomination_cycles CASCADE;

-- Create updated function to handle nomination cycles
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER AS $$
DECLARE
  new_cycle_id uuid;
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

    -- Create next cycle entry
    INSERT INTO nomination_cycles (
      start_date,
      end_date,
      period,
      nomination_area_id,
      status
    )
    VALUES (
      NEW.next_nomination_start_date,
      NEW.next_nomination_end_date,
      NEW.next_nomination_period,
      NEW.next_nomination_area_id,
      'next'
    )
    RETURNING id INTO NEW.next_cycle_id;
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
    NEW.ongoing_cycle_id := NEW.next_cycle_id;

    -- Update cycle status
    UPDATE nomination_cycles
    SET status = 'ongoing'
    WHERE id = NEW.next_cycle_id;

    -- Set next cycle to start at midnight the day after ongoing cycle ends
    NEW.next_nomination_start_date := date_trunc('day', NEW.ongoing_nomination_end_date + interval '1 day')::timestamptz + interval '23 hours';
    NEW.next_nomination_area_id := NULL;
    NEW.next_nomination_period := NULL;
    NEW.next_nomination_end_date := NULL;
    NEW.next_cycle_id := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER handle_nomination_cycles_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION handle_nomination_cycles();

-- Execute the function to check current cycles
SELECT check_and_update_nomination_cycles();

-- Verify the current state
SELECT 
  'Current state:' as info,
  to_char(next_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_start,
  to_char(next_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_end,
  next_nomination_period,
  next_nomination_area_id,
  next_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  ongoing_nomination_period,
  ongoing_nomination_area_id,
  ongoing_cycle_id
FROM settings;