-- Drop existing function and trigger
DROP FUNCTION IF EXISTS set_nomination_cycle_id CASCADE;

-- Create updated function to set cycle dates on new nominations
CREATE OR REPLACE FUNCTION set_nomination_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings with ongoing cycle
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;
  
  IF settings_record.ongoing_nomination_start_date IS NULL OR settings_record.ongoing_nomination_end_date IS NULL THEN
    RAISE EXCEPTION 'No ongoing nomination cycle found';
  END IF;
  
  -- Set cycle dates from the ongoing cycle
  NEW.nomination_cycle_start := settings_record.ongoing_nomination_start_date;
  NEW.nomination_cycle_end := settings_record.ongoing_nomination_end_date;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new nominations
CREATE TRIGGER set_nomination_cycle_id_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION set_nomination_cycle_id();

-- Verify the trigger works by checking existing nominations
SELECT 
  'Nominations state:' as info,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (
    WHERE nomination_cycle_start = (SELECT ongoing_nomination_start_date FROM settings LIMIT 1)
    AND nomination_cycle_end = (SELECT ongoing_nomination_end_date FROM settings LIMIT 1)
  ) as ongoing_nominations
FROM nominations;