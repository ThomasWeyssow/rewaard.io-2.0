-- Drop all existing policies
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "client_select_policy" ON clients;
DROP POLICY IF EXISTS "client_insert_policy" ON clients;
DROP POLICY IF EXISTS "client_update_policy" ON clients;
DROP POLICY IF EXISTS "client_delete_policy" ON clients;
DROP POLICY IF EXISTS "client_modules_select_policy" ON client_modules;
DROP POLICY IF EXISTS "client_modules_insert_policy" ON client_modules;
DROP POLICY IF EXISTS "client_modules_update_policy" ON client_modules;
DROP POLICY IF EXISTS "client_modules_delete_policy" ON client_modules;

-- Create super simple policies for all tables
CREATE POLICY "allow_all_profiles"
  ON profiles FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "allow_all_clients"
  ON clients FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "allow_all_client_modules"
  ON client_modules FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

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

-- Ensure Redspher client exists and is properly configured
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

  -- Ensure all modules are linked to Redspher
  INSERT INTO client_modules (client_id, module_id, is_active)
  SELECT redspher_id, m.id, true
  FROM modules m
  WHERE NOT EXISTS (
    SELECT 1 
    FROM client_modules cm 
    WHERE cm.client_id = redspher_id 
    AND cm.module_id = m.id
  );

  -- Make sure all modules are active
  UPDATE client_modules
  SET is_active = true
  WHERE client_id = redspher_id;

  -- Link all profiles to Redspher
  UPDATE profiles
  SET client_id = redspher_id
  WHERE client_id IS NULL;
END $$;