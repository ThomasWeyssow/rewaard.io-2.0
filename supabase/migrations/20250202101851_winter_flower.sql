-- Drop existing function if it exists
DROP FUNCTION IF EXISTS calculate_nomination_dates CASCADE;

-- Create updated function for nomination cycle transitions
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
  IF CURRENT_TIMESTAMP >= NEW.next_nomination_start_date THEN
    -- Move next cycle to ongoing cycle
    NEW.ongoing_nomination_start_date := NEW.next_nomination_start_date;
    NEW.ongoing_nomination_end_date := NEW.next_nomination_end_date;
    NEW.ongoing_nomination_area_id := NEW.next_nomination_area_id;
    
    -- Calculate new next cycle dates
    NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date;
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSIF NEW.nomination_period = 'bi-monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    ELSE -- '3-minutes'
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '3 minutes';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create or replace trigger
DROP TRIGGER IF EXISTS calculate_nomination_dates_trigger ON settings;

CREATE TRIGGER calculate_nomination_dates_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION calculate_nomination_dates();

-- Reset current cycles to start fresh
UPDATE settings 
SET 
  next_nomination_start_date = CURRENT_TIMESTAMP + INTERVAL '1 minute',
  next_nomination_end_date = NULL,
  ongoing_nomination_start_date = NULL,
  ongoing_nomination_end_date = NULL,
  ongoing_nomination_area_id = NULL
WHERE id IS NOT NULL;