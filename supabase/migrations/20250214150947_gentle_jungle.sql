-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create simplified policies without recursion
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Ensure the voter is the authenticated user
    voter_id = auth.uid()
    AND
    -- Only during an active cycle
    EXISTS (
      SELECT 1 
      FROM settings s 
      WHERE s.ongoing_nomination_start_date IS NOT NULL
      AND s.ongoing_nomination_end_date > CURRENT_TIMESTAMP
    )
  );

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
    AND id != NEW.id
  ) THEN
    RAISE EXCEPTION 'User has already submitted a nomination for this cycle';
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

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_nominations_voter_id 
ON nominations(voter_id);

CREATE INDEX IF NOT EXISTS idx_nominations_nominee_id 
ON nominations(nominee_id);

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
  ) as active_cycle_exists
FROM nominations;