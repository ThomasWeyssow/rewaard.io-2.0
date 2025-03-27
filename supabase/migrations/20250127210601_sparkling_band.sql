-- Vérifier l'état des associations
DO $$ 
DECLARE 
  redspher_client record;
  user_profile record;
  modules_count integer;
  client_modules_count integer;
BEGIN
  -- 1. Vérifier le client Redspher
  SELECT * INTO redspher_client 
  FROM clients 
  WHERE name = 'Redspher';

  IF redspher_client IS NULL THEN
    RAISE NOTICE 'ERREUR: Client Redspher non trouvé dans la table clients';
  ELSE
    RAISE NOTICE 'OK: Client Redspher trouvé avec ID=%', redspher_client.id;
  END IF;

  -- 2. Vérifier le profil utilisateur
  SELECT * INTO user_profile
  FROM profiles
  WHERE email = 'nicolas@gmail.com';

  IF user_profile IS NULL THEN
    RAISE NOTICE 'ERREUR: Profil utilisateur non trouvé';
  ELSE
    RAISE NOTICE 'OK: Profil utilisateur trouvé avec ID=% et client_id=%',
      user_profile.id,
      COALESCE(user_profile.client_id::text, 'NULL');
  END IF;

  -- 3. Vérifier l'association
  IF user_profile IS NOT NULL AND redspher_client IS NOT NULL THEN
    IF user_profile.client_id = redspher_client.id THEN
      RAISE NOTICE 'OK: L''utilisateur est correctement associé au client Redspher';
    ELSE
      RAISE NOTICE 'ERREUR: L''utilisateur n''est pas associé au bon client (attendu=%, actuel=%)',
        redspher_client.id,
        COALESCE(user_profile.client_id::text, 'NULL');
    END IF;
  END IF;

  -- 4. Vérifier les modules
  SELECT COUNT(*) INTO modules_count FROM modules;
  SELECT COUNT(*) INTO client_modules_count 
  FROM client_modules 
  WHERE client_id = redspher_client.id;

  RAISE NOTICE 'Modules: % modules trouvés, % modules associés au client Redspher',
    modules_count,
    client_modules_count;

  -- 5. Afficher les modules actifs
  RAISE NOTICE 'Modules actifs pour Redspher:';
  FOR redspher_client IN (
    SELECT m.name, cm.is_active
    FROM modules m
    JOIN client_modules cm ON cm.module_id = m.id
    WHERE cm.client_id = redspher_client.id
  ) LOOP
    RAISE NOTICE '- %: %', 
      redspher_client.name, 
      CASE WHEN redspher_client.is_active THEN 'actif' ELSE 'inactif' END;
  END LOOP;
END $$;