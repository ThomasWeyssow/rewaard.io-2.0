-- Log current state
DO $$ 
DECLARE 
  redspher_client record;
  rewards_module record;
  client_module record;
BEGIN
  -- Get Redspher client
  SELECT * INTO redspher_client 
  FROM clients 
  WHERE name = 'Redspher';

  -- Get employee-rewards module
  SELECT * INTO rewards_module 
  FROM modules 
  WHERE name = 'employee-rewards';

  -- Get client module state
  SELECT * INTO client_module 
  FROM client_modules 
  WHERE client_id = redspher_client.id 
  AND module_id = rewards_module.id;

  -- Log current state
  RAISE NOTICE 'Current state: client=%, module=%, association=%', 
    redspher_client.id, 
    rewards_module.id,
    client_module.is_active;

  -- Ensure module exists and is active
  INSERT INTO client_modules (client_id, module_id, is_active)
  VALUES (redspher_client.id, rewards_module.id, true)
  ON CONFLICT (client_id, module_id) 
  DO UPDATE SET is_active = true;
END $$;

-- Double check the state
SELECT 
  c.name as client_name,
  m.name as module_name,
  cm.is_active
FROM 
  clients c
  JOIN client_modules cm ON c.id = cm.client_id
  JOIN modules m ON m.id = cm.module_id
WHERE 
  c.name = 'Redspher'
  AND m.name = 'employee-rewards';