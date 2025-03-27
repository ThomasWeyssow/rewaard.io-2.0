-- Drop the unique constraint that's causing issues
ALTER TABLE nominations
DROP CONSTRAINT IF EXISTS nominations_voter_unique_per_cycle;

-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create super simple policies that allow basic operations
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (voter_id = auth.uid());

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (voter_id = auth.uid());

-- Add function to check for duplicate nominations
CREATE OR REPLACE FUNCTION check_duplicate_nominations()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM nominations 
    WHERE voter_id = NEW.voter_id
  ) THEN
    RAISE EXCEPTION 'User has already submitted a nomination';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to handle duplicate check
DROP TRIGGER IF EXISTS check_duplicate_nominations_trigger ON nominations;
CREATE TRIGGER check_duplicate_nominations_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION check_duplicate_nominations();

-- Verify current nominations
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (WHERE voter_id = auth.uid()) as my_nominations
FROM nominations;