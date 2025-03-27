-- Drop existing trigger and function
DROP TRIGGER IF EXISTS handle_nomination_cycles_trigger ON settings;
DROP FUNCTION IF EXISTS handle_nomination_cycles();

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
      NEW.next_nomination_end_date := (
        date_trunc('month', NEW.next_nomination_start_date) + 
        interval '1 month' - 
        interval '1 second'
      )::timestamptz;
    ELSE -- 'bi-monthly'
      -- End date is last day of next month at 23:59:59 Paris time
      NEW.next_nomination_end_date := (
        date_trunc('month', NEW.next_nomination_start_date) + 
        interval '2 months' - 
        interval '1 second'
      )::timestamptz;
    END IF;

    -- Log the calculated dates
    RAISE NOTICE 'Calculated dates:';
    RAISE NOTICE '- Start: %', NEW.next_nomination_start_date;
    RAISE NOTICE '- End: %', NEW.next_nomination_end_date;
    RAISE NOTICE '- Period: %', NEW.next_nomination_period;
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

    -- Log the transition
    RAISE NOTICE 'Cycle transition:';
    RAISE NOTICE '- Ongoing start: %', NEW.ongoing_nomination_start_date;
    RAISE NOTICE '- Ongoing end: %', NEW.ongoing_nomination_end_date;
    RAISE NOTICE '- Ongoing period: %', NEW.ongoing_nomination_period;
    RAISE NOTICE '- Next start: %', NEW.next_nomination_start_date;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER handle_nomination_cycles_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION handle_nomination_cycles();

-- Verify current settings state
SELECT 
  'Current settings state:' as info,
  to_char(next_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_start,
  to_char(next_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_end,
  next_nomination_period,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  ongoing_nomination_period
FROM settings;