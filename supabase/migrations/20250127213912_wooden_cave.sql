-- Ensure proper module setup with pages
DO $$ 
DECLARE 
  redspher_id uuid;
  rewards_module_id uuid;
  eotm_module_id uuid;
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

  -- Drop and recreate modules to ensure clean state
  DELETE FROM modules WHERE name IN ('employee-rewards', 'employee-of-the-month');

  -- Create rewards module
  INSERT INTO modules (name, description, features, pages)
  VALUES (
    'employee-rewards',
    'Système de récompenses',
    ARRAY[
      'Gestion des employés',
      'Attribution de points',
      'Catalogue de récompenses'
    ],
    ARRAY['employees', 'rewards']
  )
  RETURNING id INTO rewards_module_id;

  -- Create EOTM module
  INSERT INTO modules (name, description, features, pages)
  VALUES (
    'employee-of-the-month',
    'Employé du mois',
    ARRAY[
      'Programme Hero',
      'Système de nominations',
      'Validation par ExCom',
      'Wall of Fame',
      'Gestion des utilisateurs',
      'Paramètres avancés'
    ],
    ARRAY['hero-program', 'voting', 'review', 'history', 'users', 'settings']
  )
  RETURNING id INTO eotm_module_id;

  -- Ensure client modules are active
  INSERT INTO client_modules (client_id, module_id, is_active)
  VALUES 
    (redspher_id, rewards_module_id, true),
    (redspher_id, eotm_module_id, true)
  ON CONFLICT (client_id, module_id) 
  DO UPDATE SET is_active = true;

  -- Link user to Redspher
  UPDATE profiles
  SET client_id = redspher_id
  WHERE email = 'nicolas@gmail.com'
  AND (client_id IS NULL OR client_id != redspher_id);

  -- Log final state
  RAISE NOTICE 'Module setup complete:';
  RAISE NOTICE '- Redspher client ID: %', redspher_id;
  RAISE NOTICE '- Rewards module ID: %', rewards_module_id;
  RAISE NOTICE '- EOTM module ID: %', eotm_module_id;
  RAISE NOTICE '- Module pages:';
  RAISE NOTICE '  * Rewards: %', (SELECT pages FROM modules WHERE id = rewards_module_id);
  RAISE NOTICE '  * EOTM: %', (SELECT pages FROM modules WHERE id = eotm_module_id);
END $$;

-- Verify final state
SELECT 
  m.name as module_name,
  m.pages as module_pages,
  cm.is_active,
  c.name as client_name
FROM modules m
JOIN client_modules cm ON cm.module_id = m.id
JOIN clients c ON c.id = cm.client_id
ORDER BY m.name;