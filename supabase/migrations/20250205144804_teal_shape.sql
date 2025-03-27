-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select_policy" ON nominations;
DROP POLICY IF EXISTS "nominations_insert_policy" ON nominations;
DROP POLICY IF EXISTS "nominations_delete_policy" ON nominations;

-- Create new simplified policies
CREATE POLICY "nominations_select_policy"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert_policy"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
      OR ongoing_nomination_start_date IS NOT NULL
    )
  );

CREATE POLICY "nominations_delete_policy"
  ON nominations FOR DELETE
  TO authenticated
  USING (
    voter_id = auth.uid() 
    AND EXISTS (
      SELECT 1 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
      OR ongoing_nomination_start_date IS NOT NULL
    )
  );

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (
    WHERE id = '336dd5d6-0cfe-4c1e-aa76-150f960963ec'
  ) as target_nomination
FROM nominations;