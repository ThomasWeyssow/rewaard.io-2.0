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
    -- Allow users to see nominations during an active cycle
    EXISTS (
      SELECT 1 
      FROM settings s 
      WHERE s.ongoing_nomination_start_date IS NOT NULL
    )
  );

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only allow nominations during an active cycle
    EXISTS (
      SELECT 1 
      FROM settings s 
      WHERE s.ongoing_nomination_start_date IS NOT NULL
      AND s.ongoing_nomination_end_date > CURRENT_TIMESTAMP
    )
    AND
    -- Ensure the voter is the authenticated user
    voter_id = auth.uid()
  );

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (
    -- Only allow users to delete their own nominations
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

-- Verify the current state
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (WHERE voter_id = auth.uid()) as my_nominations,
  COUNT(*) FILTER (WHERE nominee_id = auth.uid()) as nominations_for_me,
  EXISTS (
    SELECT 1 
    FROM nominations 
    WHERE id = '0d7d6e26-b1e9-4829-8e19-07b989fb8b3f'
  ) as target_nomination_exists
FROM nominations;