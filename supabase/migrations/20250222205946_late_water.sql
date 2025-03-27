-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Drop existing trigger and function first
DROP TRIGGER IF EXISTS check_duplicate_nominations_trigger ON nominations;
DROP FUNCTION IF EXISTS check_duplicate_nominations();

-- Create simplified policies for nominations
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

-- Create function to check for duplicate nominations
CREATE OR REPLACE FUNCTION check_duplicate_nominations()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM nominations 
    WHERE voter_id = NEW.voter_id
    AND id != NEW.id
  ) THEN
    RAISE EXCEPTION 'You can only submit one nomination at a time';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new nominations
CREATE TRIGGER check_duplicate_nominations_trigger
  BEFORE INSERT OR UPDATE ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION check_duplicate_nominations();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_nominations_voter_id 
ON nominations(voter_id);

CREATE INDEX IF NOT EXISTS idx_nominations_nominee_id 
ON nominations(nominee_id);

-- Verify the current state
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (WHERE voter_id = auth.uid()) as my_nominations
FROM nominations;