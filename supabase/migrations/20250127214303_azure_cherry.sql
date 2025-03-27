-- Ensure proper module setup with pages
DO $$ 
DECLARE 
  redspher_id uuid;
  rewards_module_id uuid;
BEGIN
  -- Get Redspher client ID
  SELECT id INTO redspher_id 
  FROM clients 
  WHERE name = 'Redspher';

  -- Get rewards module ID
  SELECT id INTO rewards_module_id
  FROM modules
  WHERE name = 'employee-rewards';

  -- Log initial state
  RAISE NOTICE 'Initial state:';
  RAISE NOTICE '- Redspher client ID: %', redspher_id;
  RAISE NOTICE '- Rewards module ID: %', rewards_module_id;
  RAISE NOTICE '- Current module status: %', (
    SELECT is_active 
    FROM client_modules 
    WHERE client_id = redspher_id 
    AND module_id = rewards_module_id
  );

  -- Update module pages if needed
  UPDATE modules 
  SET pages = ARRAY['employees', 'rewards']
  WHERE id = rewards_module_id
  AND NOT (pages @> ARRAY['employees', 'rewards']::text[]);

  -- Ensure rewards module is active for Redspher
  DELETE FROM client_modules
  WHERE client_id = redspher_id
  AND module_id = rewards_module_id;

  INSERT INTO client_modules (client_id, module_id, is_active)
  VALUES (redspher_id, rewards_module_id, true);

  -- Verify final state
  RAISE NOTICE 'Final state:';
  RAISE NOTICE '- Module status: %', (
    SELECT is_active 
    FROM client_modules 
    WHERE client_id = redspher_id 
    AND module_id = rewards_module_id
  );
  RAISE NOTICE '- Module pages: %', (
    SELECT pages 
    FROM modules 
    WHERE id = rewards_module_id
  );
END $$;

-- Double check the state
SELECT 
  m.name as module_name,
  m.pages as module_pages,
  cm.is_active,
  c.name as client_name
FROM modules m
JOIN client_modules cm ON cm.module_id = m.id
JOIN clients c ON c.id = cm.client_id
WHERE m.name = 'employee-rewards'
AND c.name = 'Redspher';