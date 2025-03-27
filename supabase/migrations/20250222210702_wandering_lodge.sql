-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS check_nomination_rules_trigger ON nominations;
DROP FUNCTION IF EXISTS check_nomination_rules();

-- Create super simple policies for nominations
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only ensure the voter is the authenticated user
    voter_id = auth.uid()
  );

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (voter_id = auth.uid());

-- Create function to check for duplicate nominations and set cycle_id
CREATE OR REPLACE FUNCTION handle_nomination_insert()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if there is an active cycle
  IF settings_record.ongoing_nomination_start_date IS NULL OR 
     settings_record.ongoing_nomination_end_date <= CURRENT_TIMESTAMP THEN
    RAISE EXCEPTION 'Nominations are currently closed';
  END IF;

  -- Check if user already has a nomination
  IF EXISTS (
    SELECT 1 
    FROM nominations 
    WHERE voter_id = NEW.voter_id
    AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) THEN
    RAISE EXCEPTION 'You can only submit one nomination at a time';
  END IF;

  -- Set cycle_id from ongoing cycle
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new nominations
CREATE TRIGGER handle_nomination_insert_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION handle_nomination_insert();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_nominations_voter_id 
ON nominations(voter_id);

CREATE INDEX IF NOT EXISTS idx_nominations_nominee_id 
ON nominations(nominee_id);

CREATE INDEX IF NOT EXISTS idx_nominations_cycle_id
ON nominations(cycle_id);

-- Verify the current state
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (WHERE voter_id = auth.uid()) as my_nominations,
  EXISTS (
    SELECT 1 
    FROM settings 
    WHERE ongoing_nomination_start_date IS NOT NULL
    AND ongoing_nomination_end_date > CURRENT_TIMESTAMP
  ) as active_cycle_exists,
  (
    SELECT ongoing_cycle_id 
    FROM settings 
    LIMIT 1
  ) as ongoing_cycle_id
FROM nominations;