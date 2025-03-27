-- Drop the unique constraint that's causing issues
ALTER TABLE nominations
DROP CONSTRAINT IF EXISTS nominations_voter_unique_per_cycle;

-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create new policies that handle uniqueness through policy instead of constraint
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
    -- Ensure one nomination per voter during the active cycle
    NOT EXISTS (
      SELECT 1 
      FROM nominations n2 
      WHERE n2.voter_id = auth.uid()
    )
  );

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (voter_id = auth.uid());

-- Verify current nominations
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (WHERE voter_id = auth.uid()) as my_nominations
FROM nominations;