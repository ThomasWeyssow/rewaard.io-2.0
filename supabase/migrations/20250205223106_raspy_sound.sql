-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create super simple policies that allow all operations during an active cycle
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
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

-- Ensure the cycle is properly set
UPDATE settings
SET ongoing_nomination_end_date = CURRENT_TIMESTAMP + interval '1 month'
WHERE ongoing_nomination_start_date IS NOT NULL
AND ongoing_nomination_end_date <= CURRENT_TIMESTAMP;

-- Verify current nominations
SELECT 
  'État des nominations:' as section,
  n.id,
  p_voter.email as voter_email,
  p_nominee.email as nominee_email,
  n.selected_areas,
  n.justification,
  s.ongoing_nomination_start_date,
  s.ongoing_nomination_end_date
FROM nominations n
JOIN profiles p_voter ON p_voter.id = n.voter_id
JOIN profiles p_nominee ON p_nominee.id = n.nominee_id
CROSS JOIN settings s;