-- Drop materialized view and related objects
DROP MATERIALIZED VIEW IF EXISTS admin_users CASCADE;
DROP TRIGGER IF EXISTS refresh_admin_users_trigger ON profile_roles;
DROP FUNCTION IF EXISTS refresh_admin_users();

-- Drop all existing policies
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

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_profile_roles_profile_role 
ON profile_roles(profile_id, role_id);