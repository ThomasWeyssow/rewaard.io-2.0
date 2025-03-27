-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read client modules" ON client_modules;
DROP POLICY IF EXISTS "Users can update client modules" ON client_modules;
DROP POLICY IF EXISTS "Users can read their client's modules" ON client_modules;
DROP POLICY IF EXISTS "Admins can manage client modules" ON client_modules;

-- Create new simplified policies
CREATE POLICY "client_modules_select"
  ON client_modules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "client_modules_update"
  ON client_modules FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "client_modules_insert"
  ON client_modules FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "client_modules_delete"
  ON client_modules FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid()
    )
  );

-- Ensure all modules are properly linked to Redspher
DO $$
DECLARE
  redspher_id uuid;
BEGIN
  -- Get Redspher client ID
  SELECT id INTO redspher_id FROM clients WHERE name = 'Redspher';
  
  -- Insert missing module associations
  INSERT INTO client_modules (client_id, module_id, is_active)
  SELECT redspher_id, m.id, true
  FROM modules m
  WHERE NOT EXISTS (
    SELECT 1 
    FROM client_modules cm 
    WHERE cm.client_id = redspher_id 
    AND cm.module_id = m.id
  );
END $$;