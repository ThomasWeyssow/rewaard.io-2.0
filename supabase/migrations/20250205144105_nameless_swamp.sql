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

-- Drop all existing policies
DROP POLICY IF EXISTS "nominations_select_policy" ON nominations;
DROP POLICY IF EXISTS "nominations_insert_policy" ON nominations;
DROP POLICY IF EXISTS "nominations_delete_policy" ON nominations;

-- Create new policies that only use cycle_id
CREATE POLICY "nominations_select_policy"
  ON nominations FOR SELECT
  TO authenticated
  USING (
    cycle_id = (
      SELECT ongoing_cycle_id 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
    )
  );

CREATE POLICY "nominations_insert_policy"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
    )
  );

CREATE POLICY "nominations_delete_policy"
  ON nominations FOR DELETE
  TO authenticated
  USING (
    voter_id = auth.uid() AND
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
  ) as ongoing_nominations,
  (SELECT ongoing_cycle_id FROM settings LIMIT 1) as current_cycle_id
FROM nominations;