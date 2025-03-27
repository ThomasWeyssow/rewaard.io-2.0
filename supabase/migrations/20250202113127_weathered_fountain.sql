-- Add nomination period columns for both cycles
ALTER TABLE settings
DROP COLUMN nomination_period,
ADD COLUMN next_nomination_period text CHECK (next_nomination_period IN ('monthly', 'bi-monthly')),
ADD COLUMN ongoing_nomination_period text CHECK (ongoing_nomination_period IN ('monthly', 'bi-monthly'));

-- Update the handle_nomination_cycles function
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate next_nomination_end_date if start date is set
  IF NEW.next_nomination_start_date IS NOT NULL THEN
    IF NEW.next_nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSE -- 'bi-monthly'
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    END IF;
  END IF;

  -- Check if we need to transition to a new cycle
  IF TG_OP = 'UPDATE' AND 
     NEW.next_nomination_start_date <= CURRENT_DATE AND 
     NEW.ongoing_nomination_start_date IS NULL THEN
    -- Move next cycle to ongoing
    NEW.ongoing_nomination_start_date := NEW.next_nomination_start_date;
    NEW.ongoing_nomination_end_date := NEW.next_nomination_end_date;
    NEW.ongoing_nomination_area_id := NEW.next_nomination_area_id;
    NEW.ongoing_nomination_period := NEW.next_nomination_period;

    -- Reset next cycle
    NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date + INTERVAL '1 day';
    NEW.next_nomination_area_id := NULL;
    NEW.next_nomination_period := NULL;
    
    -- Calculate new end date based on period
    IF NEW.next_nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSE -- 'bi-monthly'
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings updated:';
  RAISE NOTICE '- Next nomination period: %', settings_record.next_nomination_period;
  RAISE NOTICE '- Ongoing nomination period: %', settings_record.ongoing_nomination_period;
END $$;