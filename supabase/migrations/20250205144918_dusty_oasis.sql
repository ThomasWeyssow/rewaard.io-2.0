-- Drop all existing policies
DROP POLICY IF EXISTS "nominations_select_policy" ON nominations;
DROP POLICY IF EXISTS "nominations_insert_policy" ON nominations;
DROP POLICY IF EXISTS "nominations_delete_policy" ON nominations;
DROP POLICY IF EXISTS "Users can read nominations" ON nominations;
DROP POLICY IF EXISTS "Users can create nominations" ON nominations;
DROP POLICY IF EXISTS "Users can delete their own nominations" ON nominations;

-- Create super simple policies
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (voter_id = auth.uid());

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (
    WHERE id = '336dd5d6-0cfe-4c1e-aa76-150f960963ec'
  ) as target_nomination,
  EXISTS (
    SELECT 1 
    FROM nominations 
    WHERE id = '336dd5d6-0cfe-4c1e-aa76-150f960963ec'
  ) as nomination_exists
FROM nominations;