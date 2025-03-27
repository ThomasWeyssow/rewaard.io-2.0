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
  WITH CHECK (true);

CREATE POLICY "profile_roles_delete"
  ON profile_roles FOR DELETE
  TO authenticated
  USING (true);