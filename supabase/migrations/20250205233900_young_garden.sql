-- Drop all existing policies
DO $$ 
BEGIN
  -- Drop all existing policies if they exist
  DROP POLICY IF EXISTS "validations_select" ON nomination_validations;
  DROP POLICY IF EXISTS "validations_insert" ON nomination_validations;
  DROP POLICY IF EXISTS "validations_delete" ON nomination_validations;
  DROP POLICY IF EXISTS "Users can read all validations" ON nomination_validations;
  DROP POLICY IF EXISTS "Users can create validations" ON nomination_validations;
  DROP POLICY IF EXISTS "Users can delete their own validations" ON nomination_validations;
END $$;

-- Create new policies that allow validating nominations from any completed cycle
CREATE POLICY "validations_select_policy"
  ON nomination_validations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "validations_insert_policy"
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
  );

CREATE POLICY "validations_delete_policy"
  ON nomination_validations FOR DELETE
  TO authenticated
  USING (
    -- Allow users to remove their own validations
    validator_id = auth.uid()
  );

-- Verify the current state
SELECT 
  'État des validations:' as section,
  COUNT(*) as total_validations,
  COUNT(*) FILTER (WHERE validator_id = auth.uid()) as my_validations
FROM nomination_validations;