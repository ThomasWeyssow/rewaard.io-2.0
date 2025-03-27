-- Drop existing policies
DROP POLICY IF EXISTS "nomination_validations_history_select" ON nomination_validations_history;

-- Create policies for nomination_validations_history
CREATE POLICY "nomination_validations_history_select"
  ON nomination_validations_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nomination_validations_history_insert"
  ON nomination_validations_history FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Verify the policies
SELECT 
  'Policies for nomination_validations_history:' as section,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'nomination_validations_history';