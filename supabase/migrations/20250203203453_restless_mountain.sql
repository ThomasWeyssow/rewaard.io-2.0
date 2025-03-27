-- Drop existing function
DROP FUNCTION IF EXISTS handle_nomination_cycles CASCADE;

-- Create simplified function for nomination cycle transitions
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate next_nomination_end_date if it's not provided
  IF NEW.next_nomination_start_date IS NOT NULL AND NEW.next_nomination_end_date IS NULL THEN
    -- Set start date to 23:00:00 UTC (midnight Paris)
    NEW.next_nomination_start_date := date_trunc('day', NEW.next_nomination_start_date) + interval '23 hours';
    
    IF NEW.next_nomination_period = 'monthly' THEN
      -- Set end date to 22:59:59 UTC (23:59:59 Paris)
      NEW.next_nomination_end_date := date_trunc('month', NEW.next_nomination_start_date) + interval '1 month' - interval '1 hour' - interval '1 second';
    ELSE -- 'bi-monthly'
      -- Set end date to 22:59:59 UTC (23:59:59 Paris)
      NEW.next_nomination_end_date := date_trunc('month', NEW.next_nomination_start_date) + interval '2 months' - interval '1 hour' - interval '1 second';
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

    -- Set next cycle to start at 23:00:00 UTC the day after ongoing cycle ends
    NEW.next_nomination_start_date := date_trunc('day', NEW.ongoing_nomination_end_date + interval '1 day') + interval '23 hours';
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

-- Reset current cycles to ensure proper UTC values
UPDATE settings 
SET 
  next_nomination_start_date = date_trunc('day', CURRENT_TIMESTAMP) + interval '1 day' + interval '23 hours',
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
  
  RAISE NOTICE 'Settings updated with fixed UTC values:';
  RAISE NOTICE '- Next nomination start (UTC): %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination end (UTC): %', settings_record.next_nomination_end_date;
END $$;