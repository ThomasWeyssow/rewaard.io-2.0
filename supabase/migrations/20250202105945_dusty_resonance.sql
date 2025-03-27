-- Drop existing function and trigger
DROP TRIGGER IF EXISTS calculate_nomination_end_date_trigger ON settings;
DROP FUNCTION IF EXISTS calculate_nomination_end_date();

-- Create improved function to handle both end date calculation and cycle transition
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate next_nomination_end_date if start date is set
  IF NEW.next_nomination_start_date IS NOT NULL THEN
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSE -- 'bi-monthly'
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    END IF;
  END IF;

  -- Check if we need to transition to a new cycle
  -- Only do this for UPDATE operations to avoid issues during initial INSERT
  IF TG_OP = 'UPDATE' AND NEW.next_nomination_start_date <= CURRENT_DATE THEN
    -- Move next cycle to ongoing
    NEW.ongoing_nomination_start_date := NEW.next_nomination_start_date;
    NEW.ongoing_nomination_end_date := NEW.next_nomination_end_date;
    NEW.ongoing_nomination_area_id := NEW.next_nomination_area_id;

    -- Reset next cycle
    NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date + INTERVAL '1 day';
    NEW.next_nomination_area_id := NULL;
    
    -- Calculate new end date based on period
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSE -- 'bi-monthly'
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create new trigger
CREATE TRIGGER handle_nomination_cycles_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION handle_nomination_cycles();

-- Log current settings state
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Current settings state:';
  RAISE NOTICE '- Next nomination start: %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination end: %', settings_record.next_nomination_end_date;
  RAISE NOTICE '- Ongoing nomination start: %', settings_record.ongoing_nomination_start_date;
  RAISE NOTICE '- Ongoing nomination end: %', settings_record.ongoing_nomination_end_date;
  RAISE NOTICE '- Nomination period: %', settings_record.nomination_period;
END $$;