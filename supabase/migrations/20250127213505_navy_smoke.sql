-- Ensure proper module setup
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

  -- Ensure modules exist
  SELECT id INTO rewards_module_id
  FROM modules
  WHERE name = 'employee-rewards';

  IF rewards_module_id IS NULL THEN
    INSERT INTO modules (name, description, features)
    VALUES (
      'employee-rewards',
      'Système de récompenses',
      ARRAY[
        'Gestion des employés',
        'Attribution de points',
        'Catalogue de récompenses'
      ]
    )
    RETURNING id INTO rewards_module_id;
  END IF;

  SELECT id INTO eotm_module_id
  FROM modules
  WHERE name = 'employee-of-the-month';

  IF eotm_module_id IS NULL THEN
    INSERT INTO modules (name, description, features)
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
      ]
    )
    RETURNING id INTO eotm_module_id;
  END IF;

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
  RAISE NOTICE 'Setup complete:';
  RAISE NOTICE '- Redspher client ID: %', redspher_id;
  RAISE NOTICE '- Rewards module ID: %', rewards_module_id;
  RAISE NOTICE '- EOTM module ID: %', eotm_module_id;
  RAISE NOTICE '- User client association: %', (
    SELECT client_id FROM profiles WHERE email = 'nicolas@gmail.com'
  );
END $$;