-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read nomination history" ON nomination_history;
DROP POLICY IF EXISTS "nomination_history_select" ON nomination_history;
DROP POLICY IF EXISTS "nomination_history_insert" ON nomination_history;

-- Create new policy that allows reading all nomination history
CREATE POLICY "nomination_history_select_policy"
  ON nomination_history FOR SELECT
  TO authenticated
  USING (true);

-- Verify the current state
SELECT 
  'État de l''historique:' as section,
  COUNT(*) as total_nominations,
  COUNT(DISTINCT nominee_id) as unique_nominees,
  COUNT(DISTINCT cycle_id) as unique_cycles
FROM nomination_history;