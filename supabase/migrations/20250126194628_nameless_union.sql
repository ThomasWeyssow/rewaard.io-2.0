-- Drop existing policies
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "client_select_policy" ON clients;
DROP POLICY IF EXISTS "client_admin_policy" ON clients;
DROP POLICY IF EXISTS "client_modules_select_policy" ON client_modules;
DROP POLICY IF EXISTS "client_modules_admin_policy" ON client_modules;

-- Create simplified policies for profiles
CREATE POLICY "profiles_select_policy"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profiles_update_policy"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Create simplified policies for clients
CREATE POLICY "client_select_policy"
  ON clients FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "client_insert_policy"
  ON clients FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

CREATE POLICY "client_update_policy"
  ON clients FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

CREATE POLICY "client_delete_policy"
  ON clients FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Create simplified policies for client_modules
CREATE POLICY "client_modules_select_policy"
  ON client_modules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "client_modules_insert_policy"
  ON client_modules FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

CREATE POLICY "client_modules_update_policy"
  ON client_modules FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

CREATE POLICY "client_modules_delete_policy"
  ON client_modules FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Ensure ndevaux has Admin role
DO $$
DECLARE
  user_id uuid;
  admin_role_id uuid;
BEGIN
  -- Get user ID for ndevaux
  SELECT id INTO user_id
  FROM profiles
  WHERE email = 'nicolas@gmail.com';

  -- Get Admin role ID
  SELECT id INTO admin_role_id
  FROM roles
  WHERE name = 'Admin';

  -- Add Admin role if not already assigned
  IF user_id IS NOT NULL AND admin_role_id IS NOT NULL THEN
    INSERT INTO profile_roles (profile_id, role_id)
    VALUES (user_id, admin_role_id)
    ON CONFLICT (profile_id, role_id) DO NOTHING;
  END IF;
END $$;