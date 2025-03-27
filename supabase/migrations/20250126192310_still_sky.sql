-- Drop existing policies
DROP POLICY IF EXISTS "profile_roles_select" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_insert" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_delete" ON profile_roles;

-- Create new simplified policies
CREATE POLICY "profile_roles_select"
  ON profile_roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profile_roles_insert"
  ON profile_roles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

CREATE POLICY "profile_roles_delete"
  ON profile_roles FOR DELETE
  TO authenticated
  USING (
    -- Admins can delete any role
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
    OR
    -- Users can delete their own roles except 'User' role
    (
      profile_id = auth.uid() 
      AND role_id NOT IN (
        SELECT id FROM roles 
        WHERE name = 'User'
      )
    )
  );