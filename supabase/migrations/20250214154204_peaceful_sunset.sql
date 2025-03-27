-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop nomination_history policies
  DROP POLICY IF EXISTS "nomination_history_select" ON nomination_history;
  DROP POLICY IF EXISTS "nomination_history_insert" ON nomination_history;
  
  -- Drop nomination_cycles policies
  DROP POLICY IF EXISTS "nomination_cycles_select" ON nomination_cycles;
  DROP POLICY IF EXISTS "nomination_cycles_insert" ON nomination_cycles;
  
  -- Drop nomination_validations_history policies
  DROP POLICY IF EXISTS "nomination_validations_history_select" ON nomination_validations_history;
  DROP POLICY IF EXISTS "nomination_validations_history_insert" ON nomination_validations_history;
END $$;

-- Create new policies for nomination_history
CREATE POLICY "nomination_history_select_v2"
  ON nomination_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nomination_history_insert_v2"
  ON nomination_history FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create policy for nomination_cycles
CREATE POLICY "nomination_cycles_select_v2"
  ON nomination_cycles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nomination_cycles_insert_v2"
  ON nomination_cycles FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create policy for nomination_validations_history
CREATE POLICY "nomination_validations_history_select_v2"
  ON nomination_validations_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nomination_validations_history_insert_v2"
  ON nomination_validations_history FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Verify the current state
SELECT 
  'État des politiques:' as section,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN (
  'nomination_history',
  'nomination_cycles',
  'nomination_validations_history'
)
ORDER BY tablename, cmd;