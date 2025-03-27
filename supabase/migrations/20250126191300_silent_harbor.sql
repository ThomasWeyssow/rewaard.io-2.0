-- Drop all existing policies
DROP POLICY IF EXISTS "Anyone can read profile roles" ON profile_roles;
DROP POLICY IF EXISTS "Admins can manage profile roles" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_read_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_admin_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_user_delete_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_select_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_insert_policy" ON profile_roles;
DROP POLICY IF EXISTS "profile_roles_delete_policy" ON profile_roles;

-- Create a materialized view to cache admin users
CREATE MATERIALIZED VIEW admin_users AS
SELECT DISTINCT p.id
FROM profiles p
JOIN profile_roles pr ON pr.profile_id = p.id
JOIN roles r ON r.id = pr.role_id
WHERE r.name = 'Admin';

-- Create index on the materialized view
CREATE UNIQUE INDEX admin_users_id_idx ON admin_users(id);

-- Create simple policies that use the materialized view
CREATE POLICY "profile_roles_select"
  ON profile_roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profile_roles_insert"
  ON profile_roles FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() IN (SELECT id FROM admin_users)
  );

CREATE POLICY "profile_roles_delete"
  ON profile_roles FOR DELETE
  TO authenticated
  USING (
    auth.uid() IN (SELECT id FROM admin_users)
    OR (
      profile_id = auth.uid() 
      AND role_id NOT IN (SELECT id FROM roles WHERE name = 'User')
    )
  );

-- Function to refresh admin users view
CREATE OR REPLACE FUNCTION refresh_admin_users()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY admin_users;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to refresh the view when profile roles change
CREATE TRIGGER refresh_admin_users_trigger
  AFTER INSERT OR DELETE OR UPDATE ON profile_roles
  FOR EACH STATEMENT
  EXECUTE FUNCTION refresh_admin_users();