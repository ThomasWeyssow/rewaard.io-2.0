-- Drop existing policies
DROP POLICY IF EXISTS "profile_roles_read_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_admin_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_user_delete_policy" ON profile_roles;

-- Create new policies with proper permissions
CREATE POLICY "Anyone can read profile roles"
  ON profile_roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage profile roles"
  ON profile_roles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_profile_roles_profile_role 
ON profile_roles(profile_id, role_id);