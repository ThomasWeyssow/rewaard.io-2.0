/*
  # Add ongoing nomination cycle management
  
  1. New Columns
    - `ongoing_nomination_start_date` (date)
    - `ongoing_nomination_end_date` (date)
    - `ongoing_nomination_area_id` (uuid, references nomination_areas)
  
  2. Function Updates
    - Update calculate_nomination_dates() to handle ongoing cycle
*/

-- Add new columns for ongoing nomination cycle
ALTER TABLE settings
ADD COLUMN ongoing_nomination_start_date date,
ADD COLUMN ongoing_nomination_end_date date,
ADD COLUMN ongoing_nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL;

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS calculate_nomination_dates_trigger ON settings;
DROP FUNCTION IF EXISTS calculate_nomination_dates();

-- Create updated function to handle both ongoing and next cycles
CREATE OR REPLACE FUNCTION calculate_nomination_dates()
RETURNS TRIGGER AS $$
DECLARE
  current_date date := CURRENT_DATE;
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

  -- Check if we need to start a new cycle
  IF current_date >= NEW.next_nomination_start_date THEN
    -- Move next cycle to ongoing cycle
    NEW.ongoing_nomination_start_date := NEW.next_nomination_start_date;
    NEW.ongoing_nomination_end_date := NEW.next_nomination_end_date;
    NEW.ongoing_nomination_area_id := NEW.next_nomination_area_id;
    
    -- Calculate new next cycle
    IF NEW.nomination_period = 'monthly' THEN
      NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date + INTERVAL '1 day';
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    ELSE
      NEW.next_nomination_start_date := NEW.ongoing_nomination_end_date + INTERVAL '1 day';
      NEW.next_nomination_end_date := NEW.next_nomination_start_date + INTERVAL '2 months' - INTERVAL '1 day';
    END IF;
    
    -- Reset next nomination area
    NEW.next_nomination_area_id := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
CREATE TRIGGER calculate_nomination_dates_trigger
  BEFORE INSERT OR UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION calculate_nomination_dates();