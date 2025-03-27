-- Drop existing policies except "Users can create nominations"
DROP POLICY IF EXISTS "Users can read nominations" ON nominations;
DROP POLICY IF EXISTS "Users can delete their own nominations" ON nominations;

-- Create new policy that only uses cycle_id
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

-- Create policy for deleting nominations
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