-- Drop existing policies
DROP POLICY IF EXISTS "validations_select_policy" ON nomination_validations;
DROP POLICY IF EXISTS "validations_insert_policy" ON nomination_validations;
DROP POLICY IF EXISTS "validations_delete_policy" ON nomination_validations;

-- Create new simplified policies for nomination validations
CREATE POLICY "validations_select"
  ON nomination_validations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "validations_insert"
  ON nomination_validations FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow ExCom members to validate nominations
    EXISTS (
      SELECT 1 
      FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'ExCom'
    )
    AND
    -- Ensure validator is the authenticated user
    validator_id = auth.uid()
  );

CREATE POLICY "validations_delete"
  ON nomination_validations FOR DELETE
  TO authenticated
  USING (
    -- Allow users to remove their own validations
    validator_id = auth.uid()
  );

-- Add unique constraint to prevent multiple validations from same validator
DROP INDEX IF EXISTS idx_nomination_validations_validator_nominee;
ALTER TABLE nomination_validations
DROP CONSTRAINT IF EXISTS nomination_validations_validator_unique;

-- Add new constraint that allows one validation per validator
ALTER TABLE nomination_validations
ADD CONSTRAINT nomination_validations_validator_unique 
UNIQUE (validator_id);

-- Verify the policies
SELECT 
  'Validation policies:' as section,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'nomination_validations'
ORDER BY policyname;