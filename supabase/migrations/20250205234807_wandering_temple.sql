-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create new policies that properly handle nominations visibility
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (
    -- Allow users to see their own nominations
    voter_id = auth.uid()
    OR
    -- Or nominations where they are the nominee
    nominee_id = auth.uid()
  );

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Ensure the voter is the authenticated user
    voter_id = auth.uid()
    AND
    -- Ensure one nomination per voter
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

-- Verify the current state
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (WHERE voter_id = auth.uid()) as my_nominations,
  COUNT(*) FILTER (WHERE nominee_id = auth.uid()) as nominations_for_me
FROM nominations;

-- Verify RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'nominations';