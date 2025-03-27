-- Drop existing client policies
DROP POLICY IF EXISTS "Users can read clients they belong to" ON clients;
DROP POLICY IF EXISTS "Admins can manage clients" ON clients;
DROP POLICY IF EXISTS "Anyone can read clients" ON clients;

-- Create new simplified client policies
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

-- Drop existing client_modules policies
DROP POLICY IF EXISTS "client_modules_select" ON client_modules;
DROP POLICY IF EXISTS "client_modules_update" ON client_modules;
DROP POLICY IF EXISTS "client_modules_insert" ON client_modules;
DROP POLICY IF EXISTS "client_modules_delete" ON client_modules;

-- Create new simplified client_modules policies
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

-- Ensure Redspher client exists
DO $$
DECLARE
  redspher_id uuid;
BEGIN
  -- Get existing Redspher client or create new one
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

  -- Update all existing modules to be active
  UPDATE client_modules
  SET is_active = true
  WHERE client_id = redspher_id;

  -- Link all profiles to Redspher if not already linked
  UPDATE profiles
  SET client_id = redspher_id
  WHERE client_id IS NULL;
END $$;