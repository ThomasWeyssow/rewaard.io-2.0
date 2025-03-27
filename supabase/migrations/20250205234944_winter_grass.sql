-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create new policies that properly handle nominations visibility and persistence
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (
    -- Allow users to see all nominations during an active cycle
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
    -- Ensure the voter is the authenticated user
    voter_id = auth.uid()
    AND
    -- Ensure one nomination per voter during the active cycle
    NOT EXISTS (
      SELECT 1 
      FROM nominations n2 
      WHERE n2.voter_id = auth.uid()
    )
    AND
    -- Only during an active cycle
    EXISTS (
      SELECT 1 
      FROM settings s 
      WHERE s.ongoing_nomination_start_date IS NOT NULL
    )
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
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_nominations_voter_id 
ON nominations(voter_id);

CREATE INDEX IF NOT EXISTS idx_nominations_nominee_id 
ON nominations(nominee_id);

-- Verify the current state
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (WHERE voter_id = auth.uid()) as my_nominations,
  COUNT(*) FILTER (WHERE nominee_id = auth.uid()) as nominations_for_me,
  EXISTS (
    SELECT 1 
    FROM settings 
    WHERE ongoing_nomination_start_date IS NOT NULL
  ) as active_cycle_exists
FROM nominations;