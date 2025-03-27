-- Drop existing policies for nomination_areas
DROP POLICY IF EXISTS "Anyone can read nomination areas" ON nomination_areas;
DROP POLICY IF EXISTS "nomination_areas_select" ON nomination_areas;

-- Create new policy for nomination_areas
CREATE POLICY "nomination_areas_select"
  ON nomination_areas FOR SELECT
  TO authenticated
  USING (true);

-- Drop existing policies for incentives
DROP POLICY IF EXISTS "Anyone can read incentives" ON incentives;
DROP POLICY IF EXISTS "incentives_select" ON incentives;

-- Create new policy for incentives
CREATE POLICY "incentives_select"
  ON incentives FOR SELECT
  TO authenticated
  USING (true);

-- Verify the current state
SELECT 
  'État des politiques:' as section,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename IN ('nomination_areas', 'incentives')
ORDER BY tablename, policyname;