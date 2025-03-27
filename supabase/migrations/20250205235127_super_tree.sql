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

-- Verify the specific nomination
SELECT 
  'État de la nomination:' as section,
  n.*,
  p_voter.email as voter_email,
  p_nominee.email as nominee_email,
  s.ongoing_nomination_start_date,
  s.ongoing_nomination_end_date,
  s.ongoing_cycle_id
FROM nominations n
JOIN profiles p_voter ON p_voter.id = n.voter_id
JOIN profiles p_nominee ON p_nominee.id = n.nominee_id
CROSS JOIN settings s
WHERE n.id = 'b022d97c-0812-4522-860a-7d6b6d428ee2';

-- Verify all nominations for the user
SELECT 
  'Nominations de l''utilisateur:' as section,
  n.id,
  p_nominee.email as nominee_email,
  n.selected_areas,
  n.justification
FROM nominations n
JOIN profiles p_nominee ON p_nominee.id = n.nominee_id
WHERE n.voter_id = 'ecc7afed-1b0a-4364-bdb4-f9b5c309808c';