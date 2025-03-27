-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create super simple policies
CREATE POLICY "allow_all_nominations"
  ON nominations FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Verify the current state
WITH nomination_check AS (
  SELECT 
    n.*,
    p_voter.email as voter_email,
    p_nominee.email as nominee_email,
    s.ongoing_nomination_start_date,
    s.ongoing_nomination_end_date
  FROM nominations n
  JOIN profiles p_voter ON p_voter.id = n.voter_id
  JOIN profiles p_nominee ON p_nominee.id = n.nominee_id
  CROSS JOIN settings s
  WHERE n.id = 'c95aee09-bd5b-417a-914a-5369e0b28cd6'
)
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM nomination_check) 
    THEN 'Nomination trouvée'
    ELSE 'Nomination non trouvée'
  END as status,
  (SELECT COUNT(*) FROM nominations) as total_nominations,
  (
    SELECT json_agg(row_to_json(nc))
    FROM nomination_check nc
  ) as nomination_details;