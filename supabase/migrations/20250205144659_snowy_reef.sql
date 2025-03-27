-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select_policy" ON nominations;
DROP POLICY IF EXISTS "nominations_insert_policy" ON nominations;
DROP POLICY IF EXISTS "nominations_delete_policy" ON nominations;

-- Create new policies that use both cycle_id and dates
CREATE POLICY "nominations_select_policy"
  ON nominations FOR SELECT
  TO authenticated
  USING (
    cycle_id = (SELECT ongoing_cycle_id FROM settings WHERE ongoing_cycle_id IS NOT NULL)
    OR (
      nomination_cycle_start = (SELECT ongoing_nomination_start_date FROM settings WHERE ongoing_nomination_start_date IS NOT NULL)
      AND nomination_cycle_end = (SELECT ongoing_nomination_end_date FROM settings WHERE ongoing_nomination_end_date IS NOT NULL)
    )
  );

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
    AND (
      cycle_id = (SELECT ongoing_cycle_id FROM settings WHERE ongoing_cycle_id IS NOT NULL)
      OR (
        nomination_cycle_start = (SELECT ongoing_nomination_start_date FROM settings WHERE ongoing_nomination_start_date IS NOT NULL)
        AND nomination_cycle_end = (SELECT ongoing_nomination_end_date FROM settings WHERE ongoing_nomination_end_date IS NOT NULL)
      )
    )
  );

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (
    WHERE cycle_id = (SELECT ongoing_cycle_id FROM settings LIMIT 1)
    OR (
      nomination_cycle_start = (SELECT ongoing_nomination_start_date FROM settings LIMIT 1)
      AND nomination_cycle_end = (SELECT ongoing_nomination_end_date FROM settings LIMIT 1)
    )
  ) as ongoing_nominations
FROM nominations;