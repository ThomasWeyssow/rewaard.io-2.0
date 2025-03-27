-- Vérifier et corriger l'état des modules pour Redspher
DO $$ 
DECLARE 
  redspher_id uuid;
  rewards_id uuid;
  eotm_id uuid;
BEGIN
  -- Get IDs
  SELECT id INTO redspher_id FROM clients WHERE name = 'Redspher';
  SELECT id INTO rewards_id FROM modules WHERE name = 'employee-rewards';
  SELECT id INTO eotm_id FROM modules WHERE name = 'employee-of-the-month';

  -- Log current state
  RAISE NOTICE 'IDs found: redspher=%, rewards=%, eotm=%', redspher_id, rewards_id, eotm_id;

  -- Ensure both modules exist and are active
  INSERT INTO client_modules (client_id, module_id, is_active)
  VALUES 
    (redspher_id, rewards_id, true),
    (redspher_id, eotm_id, true)
  ON CONFLICT (client_id, module_id) 
  DO UPDATE SET is_active = true;

  -- Verify final state
  RAISE NOTICE 'Final state:';
  RAISE NOTICE 'Rewards module: %', (
    SELECT is_active 
    FROM client_modules 
    WHERE client_id = redspher_id AND module_id = rewards_id
  );
  RAISE NOTICE 'EOTM module: %', (
    SELECT is_active 
    FROM client_modules 
    WHERE client_id = redspher_id AND module_id = eotm_id
  );
END $$;

-- Double check all module states
SELECT 
  c.name as client_name,
  m.name as module_name,
  cm.is_active,
  cm.created_at
FROM 
  clients c
  JOIN client_modules cm ON c.id = cm.client_id
  JOIN modules m ON m.id = cm.module_id
WHERE 
  c.name = 'Redspher'
ORDER BY 
  m.name;