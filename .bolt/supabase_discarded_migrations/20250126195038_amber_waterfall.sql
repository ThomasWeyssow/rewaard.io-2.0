-- Drop existing policies
DROP POLICY IF EXISTS "allow_all_profiles" ON profiles;
DROP POLICY IF EXISTS "allow_all_clients" ON clients;
DROP POLICY IF EXISTS "allow_all_client_modules" ON client_modules;
DROP POLICY IF EXISTS "allow_all_profile_roles" ON profile_roles;

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

CREATE POLICY "client_admin_policy"
  ON clients FOR ALL
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

CREATE POLICY "client_modules_admin_policy"
  ON client_modules FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Create simplified policies for profile_roles
CREATE POLICY "profile_roles_select_policy"
  ON profile_roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profile_roles_admin_policy"
  ON profile_roles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Ensure Redspher client exists and modules are active
DO $$
DECLARE
  redspher_id uuid;
BEGIN
  -- Get or create Redspher client
  SELECT id INTO redspher_id
  FROM clients
  WHERE name = 'Redspher';

  IF redspher_id IS NULL THEN
    INSERT INTO clients (name)
    VALUES ('Redspher')
    RETURNING id INTO redspher_id;
  END IF;

  -- Ensure all modules are linked to Redspher and active
  INSERT INTO client_modules (client_id, module_id, is_active)
  SELECT redspher_id, m.id, true
  FROM modules m
  WHERE NOT EXISTS (
    SELECT 1 
    FROM client_modules cm 
    WHERE cm.client_id = redspher_id 
    AND cm.module_id = m.id
  );

  -- Make sure all existing modules are active
  UPDATE client_modules
  SET is_active = true
  WHERE client_id = redspher_id;

  -- Link all profiles to Redspher if not already linked
  UPDATE profiles
  SET client_id = redspher_id
  WHERE client_id IS NULL;
END $$;