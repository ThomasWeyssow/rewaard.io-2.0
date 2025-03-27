-- Create function to calculate end date
CREATE OR REPLACE FUNCTION calculate_nomination_end_date()
RETURNS TRIGGER AS $$
BEGIN
  -- Only calculate end date if start date is set and end date is NULL
  IF NEW.next_nomination_start_date IS NOT NULL AND NEW.next_nomination_end_date IS NULL THEN
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSE -- 'bi-monthly'
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER calculate_nomination_end_date_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION calculate_nomination_end_date();

-- Log current settings state
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Current settings state:';
  RAISE NOTICE '- Next nomination start: %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination end: %', settings_record.next_nomination_end_date;
  RAISE NOTICE '- Nomination period: %', settings_record.nomination_period;
END $$;