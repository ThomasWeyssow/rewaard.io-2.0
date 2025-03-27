-- Update existing nominations to link with ongoing cycle
UPDATE nominations n
SET 
  cycle_id = s.ongoing_cycle_id,
  nomination_cycle_start = s.ongoing_nomination_start_date,
  nomination_cycle_end = s.ongoing_nomination_end_date
FROM settings s
WHERE s.ongoing_cycle_id IS NOT NULL
  AND n.nomination_cycle_start = s.ongoing_nomination_start_date
  AND n.nomination_cycle_end = s.ongoing_nomination_end_date;

-- Drop existing policy
DROP POLICY IF EXISTS "Users can read ongoing nominations" ON nominations;

-- Create new policy that allows reading nominations from the ongoing cycle
CREATE POLICY "Users can read ongoing nominations"
  ON nominations FOR SELECT
  TO authenticated
  USING (
    nomination_cycle_start = (SELECT ongoing_nomination_start_date FROM settings LIMIT 1)
    AND nomination_cycle_end = (SELECT ongoing_nomination_end_date FROM settings LIMIT 1)
  );

-- Verify nominations for ongoing cycle
SELECT 
  'Ongoing nominations:' as info,
  n.*,
  s.ongoing_nomination_start_date,
  s.ongoing_nomination_end_date
FROM nominations n
CROSS JOIN settings s
WHERE 
  n.nomination_cycle_start = s.ongoing_nomination_start_date
  AND n.nomination_cycle_end = s.ongoing_nomination_end_date;