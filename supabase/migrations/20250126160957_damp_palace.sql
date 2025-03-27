-- Drop existing policy
DROP POLICY IF EXISTS "Users can manage profile roles" ON profile_roles;

-- Create new policies with more specific permissions
CREATE POLICY "Users can read profile roles"
  ON profile_roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage all profile roles"
  ON profile_roles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  );

CREATE POLICY "Users can delete their own roles except User role"
  ON profile_roles FOR DELETE
  TO authenticated
  USING (
    profile_id = auth.uid() 
    AND role_id NOT IN (
      SELECT id FROM roles WHERE name = 'User'
    )
  );