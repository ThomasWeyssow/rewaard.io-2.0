-- Drop existing policies if any
DROP POLICY IF EXISTS "Anyone can read nomination cycles" ON nomination_cycles;
DROP POLICY IF EXISTS "Anyone can manage nomination cycles" ON nomination_cycles;

-- Create simplified policies for nomination_cycles
CREATE POLICY "nomination_cycles_select"
  ON nomination_cycles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nomination_cycles_insert"
  ON nomination_cycles FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "nomination_cycles_update"
  ON nomination_cycles FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "nomination_cycles_delete"
  ON nomination_cycles FOR DELETE
  TO authenticated
  USING (true);

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_cycles,
  COUNT(*) FILTER (WHERE status = 'ongoing') as ongoing_cycles,
  COUNT(*) FILTER (WHERE status = 'next') as next_cycles,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_cycles
FROM nomination_cycles;