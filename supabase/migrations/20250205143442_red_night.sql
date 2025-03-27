-- Drop existing policies
DROP POLICY IF EXISTS "Users can read nominations" ON nominations;
DROP POLICY IF EXISTS "Users can create nominations" ON nominations;
DROP POLICY IF EXISTS "Users can delete their own nominations" ON nominations;

-- Create new policies that only use cycle_id
CREATE POLICY "Users can read nominations"
  ON nominations FOR SELECT
  TO authenticated
  USING (
    cycle_id = (
      SELECT ongoing_cycle_id 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
    )
  );

CREATE POLICY "Users can create nominations"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
    )
  );

CREATE POLICY "Users can delete their own nominations"
  ON nominations FOR DELETE
  TO authenticated
  USING (
    voter_id = auth.uid() AND
    cycle_id = (
      SELECT ongoing_cycle_id 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
    )
  );

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_nominations,
  COUNT(*) FILTER (
    WHERE cycle_id = (SELECT ongoing_cycle_id FROM settings LIMIT 1)
  ) as ongoing_nominations,
  (SELECT ongoing_cycle_id FROM settings LIMIT 1) as current_cycle_id
FROM nominations;