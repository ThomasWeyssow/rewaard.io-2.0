-- Drop existing function
DROP FUNCTION IF EXISTS handle_nomination_cycles CASCADE;

-- Create updated function for nomination cycle transitions
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate next_nomination_end_date if it's not provided
  IF NEW.next_nomination_start_date IS NOT NULL AND NEW.next_nomination_end_date IS NULL THEN
    -- Convert to Paris timezone, set to midnight, then back to UTC
    NEW.next_nomination_start_date := (
      date_trunc('day', NEW.next_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris')
      AT TIME ZONE 'Europe/Paris' AT TIME ZONE 'UTC'
    )::timestamptz;
    
    IF NEW.next_nomination_period = 'monthly' THEN
      -- Add exactly one month and set to 23:59:59 Paris time
      NEW.next_nomination_end_date := (
        (date_trunc('month', NEW.next_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris') + interval '1 month' - interval '1 second')
        AT TIME ZONE 'Europe/Paris' AT TIME ZONE 'UTC'
      )::timestamptz;
    ELSE -- 'bi-monthly'
      -- Add exactly two months and set to 23:59:59 Paris time
      NEW.next_nomination_end_date := (
        (date_trunc('month', NEW.next_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris') + interval '2 month' - interval '1 second')
        AT TIME ZONE 'Europe/Paris' AT TIME ZONE 'UTC'
      )::timestamptz;
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

    -- Set next cycle to start at midnight Paris time the day after ongoing cycle ends
    NEW.next_nomination_start_date := (
      date_trunc('day', (NEW.ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris' + interval '1 day'))
      AT TIME ZONE 'Europe/Paris' AT TIME ZONE 'UTC'
    )::timestamptz;
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

-- Reset current cycles to ensure proper timezone handling
UPDATE settings 
SET 
  next_nomination_start_date = (
    date_trunc('day', CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris' + interval '1 day')
    AT TIME ZONE 'Europe/Paris' AT TIME ZONE 'UTC'
  )::timestamptz,
  next_nomination_end_date = NULL,
  ongoing_nomination_start_date = NULL,
  ongoing_nomination_end_date = NULL,
  ongoing_nomination_area_id = NULL
WHERE id IS NOT NULL;

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings updated with Paris timezone:';
  RAISE NOTICE '- Next nomination start (UTC): %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination start (Paris): % ', settings_record.next_nomination_start_date AT TIME ZONE 'Europe/Paris';
  RAISE NOTICE '- Next nomination end (UTC): %', settings_record.next_nomination_end_date;
  RAISE NOTICE '- Next nomination end (Paris): %', settings_record.next_nomination_end_date AT TIME ZONE 'Europe/Paris';
END $$;