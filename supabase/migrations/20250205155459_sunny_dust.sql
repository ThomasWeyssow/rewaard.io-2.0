-- Drop existing policies if any
DROP POLICY IF EXISTS "Anyone can read nomination history" ON nomination_history;

-- Create simplified policies for nomination_history
CREATE POLICY "nomination_history_select"
  ON nomination_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nomination_history_insert"
  ON nomination_history FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_history_entries,
  COUNT(DISTINCT cycle_id) as unique_cycles,
  MIN(created_at) as oldest_entry,
  MAX(created_at) as newest_entry
FROM nomination_history;