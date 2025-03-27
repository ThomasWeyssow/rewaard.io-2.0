-- Drop existing function and trigger
DROP FUNCTION IF EXISTS set_nomination_cycle_id CASCADE;

-- Create updated function to set cycle id on new nominations
CREATE OR REPLACE FUNCTION set_nomination_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings with ongoing cycle
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;
  
  IF settings_record.ongoing_cycle_id IS NULL THEN
    RAISE EXCEPTION 'No ongoing nomination cycle found';
  END IF;
  
  -- Set cycle id from the ongoing cycle
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new nominations
CREATE TRIGGER set_nomination_cycle_id_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION set_nomination_cycle_id();

-- Drop redundant columns from nominations
ALTER TABLE nominations
DROP COLUMN nomination_cycle_start,
DROP COLUMN nomination_cycle_end;

-- Drop redundant columns from nomination_history
ALTER TABLE nomination_history
DROP COLUMN cycle_start_date,
DROP COLUMN cycle_end_date;

-- Update policies to use cycle_id
DROP POLICY IF EXISTS "Users can read nominations" ON nominations;
CREATE POLICY "Users can read nominations"
  ON nominations FOR SELECT
  TO authenticated
  USING (
    cycle_id = (
      SELECT ongoing_cycle_id 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
    )
  );

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (
    WHERE cycle_id = (SELECT ongoing_cycle_id FROM settings LIMIT 1)
  ) as ongoing_nominations
FROM nominations;