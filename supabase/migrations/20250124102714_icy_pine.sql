-- Add columns for nomination cycle dates
ALTER TABLE settings
ADD COLUMN next_nomination_start_date date,
ADD COLUMN next_nomination_end_date date;

-- Function to calculate next nomination end date
CREATE OR REPLACE FUNCTION calculate_nomination_end_date()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate next_nomination_end_date based on frequency
  IF NEW.next_nomination_start_date IS NOT NULL THEN
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSE
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically calculate end date
CREATE TRIGGER calculate_nomination_end_date_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION calculate_nomination_end_date();