-- Créer le client Redspher s'il n'existe pas
DO $$ 
DECLARE 
  redspher_id uuid;
BEGIN
  -- Vérifier si le client Redspher existe
  SELECT id INTO redspher_id
  FROM clients
  WHERE name = 'Redspher';

  -- Créer le client s'il n'existe pas
  IF redspher_id IS NULL THEN
    INSERT INTO clients (name)
    VALUES ('Redspher')
    RETURNING id INTO redspher_id;
    
    RAISE NOTICE 'Client Redspher créé avec ID: %', redspher_id;
  ELSE
    RAISE NOTICE 'Client Redspher existant avec ID: %', redspher_id;
  END IF;

  -- Mettre à jour le profil de l'utilisateur
  UPDATE profiles
  SET client_id = redspher_id
  WHERE email = 'nicolas@gmail.com'
  AND (client_id IS NULL OR client_id != redspher_id);

  -- Vérifier la mise à jour
  IF FOUND THEN
    RAISE NOTICE 'Profil utilisateur mis à jour avec client_id: %', redspher_id;
  ELSE
    RAISE NOTICE 'Aucune mise à jour nécessaire pour l''utilisateur';
  END IF;

  -- Vérifier l'état final
  RAISE NOTICE 'État final:';
  RAISE NOTICE 'Client: %', (SELECT row_to_json(c) FROM clients c WHERE id = redspher_id);
  RAISE NOTICE 'Utilisateur: %', (SELECT row_to_json(p) FROM profiles p WHERE email = 'nicolas@gmail.com');
END $$;