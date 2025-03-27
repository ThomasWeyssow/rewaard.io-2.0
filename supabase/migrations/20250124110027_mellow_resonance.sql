-- Add columns for ongoing nomination cycle
ALTER TABLE settings
ADD COLUMN ongoing_nomination_start_date date,
ADD COLUMN ongoing_nomination_end_date date,
ADD COLUMN ongoing_nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL;

-- Update function to handle ongoing cycle
CREATE OR REPLACE FUNCTION calculate_nomination_dates()
RETURNS TRIGGER AS $$
DECLARE
  current_date date := CURRENT_DATE;
BEGIN
  -- Calculate next_nomination_end_date based on frequency
  IF NEW.next_nomination_start_date IS NOT NULL THEN
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSE
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    END IF;
  END IF;

  -- Check if we need to start a new cycle
  IF current_date >= NEW.next_nomination_start_date THEN
    -- Move next cycle to ongoing cycle
    NEW.ongoing_nomination_start_date := NEW.next_nomination_start_date;
    NEW.ongoing_nomination_end_date := NEW.next_nomination_end_date;
    NEW.ongoing_nomination_area_id := NEW.next_nomination_area_id;
    
    -- Calculate new next cycle dates
    NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date + INTERVAL '1 day';
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSE
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    END IF;
    
    -- Reset next nomination area
    NEW.next_nomination_area_id := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger
DROP TRIGGER IF EXISTS calculate_nomination_end_date_trigger ON settings;

-- Create new trigger
CREATE TRIGGER calculate_nomination_dates_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION calculate_nomination_dates();