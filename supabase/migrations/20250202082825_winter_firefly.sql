-- Add 3-minute cycle option
ALTER TABLE settings
DROP CONSTRAINT IF EXISTS settings_nomination_period_check;

ALTER TABLE settings
ADD CONSTRAINT settings_nomination_period_check 
CHECK (nomination_period IN ('monthly', 'bi-monthly', '3-minutes'));

-- Update current settings to use 3-minute cycle
UPDATE settings
SET nomination_period = '3-minutes'
WHERE id IS NOT NULL;

-- Update the calculate_nomination_dates function
CREATE OR REPLACE FUNCTION calculate_nomination_dates()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate next_nomination_end_date based on frequency
  IF NEW.next_nomination_start_date IS NOT NULL THEN
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSIF NEW.nomination_period = 'bi-monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    ELSE -- '3-minutes'
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '3 minutes';
    END IF;
  END IF;

  -- Check if we need to start a new cycle
  IF CURRENT_TIMESTAMP >= NEW.next_nomination_start_date::timestamp THEN
    -- Move next cycle to ongoing cycle
    NEW.ongoing_nomination_start_date := NEW.next_nomination_start_date;
    NEW.ongoing_nomination_end_date := NEW.next_nomination_end_date;
    NEW.ongoing_nomination_area_id := NEW.next_nomination_area_id;
    
    -- Calculate new next cycle dates
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date + INTERVAL '1 day';
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSIF NEW.nomination_period = 'bi-monthly' THEN
      NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date + INTERVAL '1 day';
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    ELSE -- '3-minutes'
      NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date;
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '3 minutes';
    END IF;
    
    -- Reset next nomination area
    NEW.next_nomination_area_id := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;