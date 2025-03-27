-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read profile roles" ON profile_roles;
DROP POLICY IF EXISTS "Users can read profile roles" ON profile_roles;
DROP POLICY IF EXISTS "Admins can manage all profile roles" ON profile_roles;
DROP POLICY IF EXISTS "Users can delete their own roles except User role" ON profile_roles;
DROP POLICY IF EXISTS "Users can manage profile roles" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_read_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_admin_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_user_delete_policy" ON profile_roles;

-- Create new policies with unique names
CREATE POLICY "profile_roles_read_policy"
  ON profile_roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profile_roles_admin_policy"
  ON profile_roles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = id
      AND raw_user_meta_data->>'department' = 'Admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = id
      AND raw_user_meta_data->>'department' = 'Admin'
    )
  );

CREATE POLICY "profile_roles_user_delete_policy"
  ON profile_roles FOR DELETE
  TO authenticated
  USING (
    profile_id = auth.uid()
    AND role_id NOT IN (
      SELECT id FROM roles WHERE name = 'User'
    )
  );