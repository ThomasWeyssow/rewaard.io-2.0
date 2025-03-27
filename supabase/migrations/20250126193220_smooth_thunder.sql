-- Ensure Redspher client exists and is properly configured
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