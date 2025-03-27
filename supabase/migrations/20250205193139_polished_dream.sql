-- Drop existing trigger and function
DROP TRIGGER IF EXISTS set_nomination_cycle_id_trigger ON nominations;
DROP FUNCTION IF EXISTS set_nomination_cycle_id;

-- Create updated function to set cycle_id on new nominations
CREATE OR REPLACE FUNCTION set_nomination_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;
  
  IF settings_record.ongoing_cycle_id IS NULL THEN
    -- Generate new ongoing_cycle_id if none exists
    WITH updated_settings AS (
      UPDATE settings
      SET ongoing_cycle_id = gen_random_uuid()
      WHERE id = settings_record.id
      RETURNING ongoing_cycle_id
    )
    SELECT ongoing_cycle_id INTO settings_record.ongoing_cycle_id
    FROM updated_settings;
    
    IF settings_record.ongoing_cycle_id IS NULL THEN
      RAISE EXCEPTION 'Failed to generate ongoing_cycle_id';
    END IF;
  END IF;
  
  -- Set cycle id from settings
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new nominations
CREATE TRIGGER set_nomination_cycle_id_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION set_nomination_cycle_id();

-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;

-- Create simplified policies
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM settings 
      WHERE ongoing_nomination_start_date IS NOT NULL
    )
  );

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (voter_id = auth.uid());

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_nominations,
  COUNT(DISTINCT cycle_id) as unique_cycles,
  EXISTS (
    SELECT 1 
    FROM settings 
    WHERE ongoing_cycle_id IS NOT NULL
  ) as has_ongoing_cycle
FROM nominations;