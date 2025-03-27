-- Drop existing function
DROP FUNCTION IF EXISTS handle_nomination_cycles CASCADE;

-- Create updated function for nomination cycle transitions
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate next_nomination_end_date if start date is set
  IF NEW.next_nomination_start_date IS NOT NULL THEN
    IF NEW.next_nomination_period = 'monthly' THEN
      -- End date is last day of the month at the same time as start
      NEW.next_nomination_end_date := (
        date_trunc('month', NEW.next_nomination_start_date) + 
        interval '1 month' - 
        interval '1 day' +
        (NEW.next_nomination_start_date::time)::interval
      );
    ELSE -- 'bi-monthly'
      -- End date is last day of next month at the same time as start
      NEW.next_nomination_end_date := (
        date_trunc('month', NEW.next_nomination_start_date) + 
        interval '2 month' - 
        interval '1 day' +
        (NEW.next_nomination_start_date::time)::interval
      );
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

    -- Reset next cycle
    NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date + interval '1 day';
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

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings updated:';
  RAISE NOTICE '- Next nomination start: %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination end: %', settings_record.next_nomination_end_date;
  RAISE NOTICE '- Ongoing nomination start: %', settings_record.ongoing_nomination_start_date;
  RAISE NOTICE '- Ongoing nomination end: %', settings_record.ongoing_nomination_end_date;
END $$;