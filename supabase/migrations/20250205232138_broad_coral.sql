-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create super simple policy that allows all operations
CREATE POLICY "allow_all_nominations"
  ON nominations FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Verify the current state
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (WHERE id = 'c7c51e87-d12b-46b7-b355-2b391b5c48b5') as target_nomination_exists,
  EXISTS (
    SELECT 1 
    FROM nominations 
    WHERE id = 'c7c51e87-d12b-46b7-b355-2b391b5c48b5'
  ) as nomination_exists
FROM nominations;