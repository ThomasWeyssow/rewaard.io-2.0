-- Drop existing policies
DROP POLICY IF EXISTS "Users can read ongoing nominations" ON nominations;
DROP POLICY IF EXISTS "Users can read all nominations" ON nominations;

-- Create new policy for reading nominations
CREATE POLICY "Users can read nominations"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

-- Update existing nominations to use the ongoing cycle dates
UPDATE nominations n
SET 
  nomination_cycle_start = s.ongoing_nomination_start_date,
  nomination_cycle_end = s.ongoing_nomination_end_date
FROM settings s
WHERE s.ongoing_nomination_start_date IS NOT NULL
  AND s.ongoing_nomination_end_date IS NOT NULL;

-- Verify the nominations
SELECT 
  'Nominations state:' as info,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (
    WHERE nomination_cycle_start = (SELECT ongoing_nomination_start_date FROM settings LIMIT 1)
    AND nomination_cycle_end = (SELECT ongoing_nomination_end_date FROM settings LIMIT 1)
  ) as ongoing_nominations
FROM nominations;