-- Drop existing policies
DROP POLICY IF EXISTS "client_select_policy" ON clients;
DROP POLICY IF EXISTS "client_insert_policy" ON clients;
DROP POLICY IF EXISTS "client_update_policy" ON clients;
DROP POLICY IF EXISTS "client_delete_policy" ON clients;

-- Create new simplified client policies
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

-- Drop existing client_modules policies
DROP POLICY IF EXISTS "client_modules_select_policy" ON client_modules;
DROP POLICY IF EXISTS "client_modules_insert_policy" ON client_modules;
DROP POLICY IF EXISTS "client_modules_update_policy" ON client_modules;
DROP POLICY IF EXISTS "client_modules_delete_policy" ON client_modules;

-- Create new simplified client_modules policies
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

-- Create Redspher client if it doesn't exist
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