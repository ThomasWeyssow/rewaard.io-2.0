-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read profile roles" ON profile_roles;
DROP POLICY IF EXISTS "Admins can manage profile roles" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_read_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_admin_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_user_delete_policy" ON profile_roles;

-- Create new policies with proper permissions
CREATE POLICY "profile_roles_select_policy"
  ON profile_roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profile_roles_insert_policy"
  ON profile_roles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM roles r
      WHERE r.name = 'Admin'
      AND r.id IN (
        SELECT role_id 
        FROM profile_roles 
        WHERE profile_id = auth.uid()
      )
    )
  );

CREATE POLICY "profile_roles_delete_policy"
  ON profile_roles FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM roles r
      WHERE r.name = 'Admin'
      AND r.id IN (
        SELECT role_id 
        FROM profile_roles 
        WHERE profile_id = auth.uid()
      )
    )
    OR (
      profile_id = auth.uid() 
      AND role_id NOT IN (
        SELECT id FROM roles WHERE name = 'User'
      )
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_profile_roles_profile_role 
ON profile_roles(profile_id, role_id);