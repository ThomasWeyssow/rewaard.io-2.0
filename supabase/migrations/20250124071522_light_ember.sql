-- Add new columns for nomination cycles
ALTER TABLE settings
ADD COLUMN next_nomination_start_date date,
ADD COLUMN next_nomination_end_date date;

-- Function to calculate next nomination dates
CREATE OR REPLACE FUNCTION calculate_nomination_dates()
RETURNS TRIGGER AS $$
BEGIN
  -- Set initial next_nomination_start_date if not set
  IF NEW.next_nomination_start_date IS NULL THEN
    NEW.next_nomination_start_date := NEW.nomination_start_date;
  END IF;

  -- Calculate next_nomination_end_date based on frequency
  IF NEW.nomination_period = 'monthly' THEN
    NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
  ELSE
    NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically calculate dates
CREATE TRIGGER calculate_nomination_dates_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION calculate_nomination_dates();