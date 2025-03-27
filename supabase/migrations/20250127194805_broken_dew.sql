-- Vérifier l'existence des modules
DO $$ 
DECLARE 
  rewards_count integer;
  eotm_count integer;
BEGIN
  -- Compter les modules
  SELECT COUNT(*) INTO rewards_count 
  FROM modules 
  WHERE name = 'employee-rewards';
  
  SELECT COUNT(*) INTO eotm_count 
  FROM modules 
  WHERE name = 'employee-of-the-month';

  -- Log l'état actuel
  RAISE NOTICE 'Modules count: rewards=%, eotm=%', rewards_count, eotm_count;

  -- Recréer les modules si nécessaire
  IF rewards_count = 0 THEN
    INSERT INTO modules (name, description, features)
    VALUES (
      'employee-rewards',
      'Système de récompenses',
      ARRAY[
        'Gestion des employés',
        'Attribution de points',
        'Catalogue de récompenses'
      ]
    );
    RAISE NOTICE 'Created employee-rewards module';
  END IF;

  IF eotm_count = 0 THEN
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
    );
    RAISE NOTICE 'Created employee-of-the-month module';
  END IF;
END $$;

-- Vérifier et corriger les associations client-modules
DO $$ 
DECLARE 
  redspher_id uuid;
  rewards_id uuid;
  eotm_id uuid;
  module_record record;
BEGIN
  -- Get IDs
  SELECT id INTO redspher_id FROM clients WHERE name = 'Redspher';
  SELECT id INTO rewards_id FROM modules WHERE name = 'employee-rewards';
  SELECT id INTO eotm_id FROM modules WHERE name = 'employee-of-the-month';

  -- Log les IDs
  RAISE NOTICE 'IDs found: redspher=%, rewards=%, eotm=%', redspher_id, rewards_id, eotm_id;

  -- Supprimer les associations existantes si elles sont désactivées
  DELETE FROM client_modules 
  WHERE client_id = redspher_id 
  AND module_id IN (rewards_id, eotm_id)
  AND is_active = false;

  -- Recréer les associations
  INSERT INTO client_modules (client_id, module_id, is_active)
  VALUES 
    (redspher_id, rewards_id, true),
    (redspher_id, eotm_id, true)
  ON CONFLICT (client_id, module_id) 
  DO UPDATE SET is_active = true;

  -- Vérifier l'état final
  RAISE NOTICE 'Final state:';
  FOR module_record IN
    SELECT 
      m.name as module_name,
      cm.is_active,
      cm.created_at
    FROM modules m
    JOIN client_modules cm ON cm.module_id = m.id
    WHERE cm.client_id = redspher_id
  LOOP
    RAISE NOTICE 'Module: %, Active: %, Created: %',
      module_record.module_name,
      module_record.is_active,
      module_record.created_at;
  END LOOP;
END $$;