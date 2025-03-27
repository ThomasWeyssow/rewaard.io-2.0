-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;

-- Create new policies that use settings for validation
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (
    cycle_id = (
      SELECT ongoing_cycle_id 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
    )
  );

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
      AND ongoing_nomination_start_date IS NOT NULL
      AND ongoing_nomination_end_date IS NOT NULL
    )
  );

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (
    voter_id = auth.uid()
    AND cycle_id = (
      SELECT ongoing_cycle_id 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
    )
  );

-- Update set_nomination_cycle_id function
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
    RAISE EXCEPTION 'No ongoing nomination cycle found';
  END IF;
  
  -- Set cycle id from settings
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;