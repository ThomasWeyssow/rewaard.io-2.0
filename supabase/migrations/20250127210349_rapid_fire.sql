-- Vérifier l'existence du client Redspher
DO $$ 
DECLARE 
  redspher_client record;
  user_profile record;
BEGIN
  -- Vérifier le client Redspher
  SELECT * INTO redspher_client 
  FROM clients 
  WHERE name = 'Redspher';

  RAISE NOTICE 'Client Redspher: %', 
    CASE 
      WHEN redspher_client IS NULL THEN 'NON TROUVÉ'
      ELSE format('ID=%s, name=%s', redspher_client.id, redspher_client.name)
    END;

  -- Vérifier le profil de l'utilisateur
  SELECT * INTO user_profile
  FROM profiles
  WHERE email = 'nicolas@gmail.com';

  RAISE NOTICE 'Profil utilisateur: %',
    CASE 
      WHEN user_profile IS NULL THEN 'NON TROUVÉ'
      ELSE format('ID=%s, email=%s, client_id=%s', 
        user_profile.id, 
        user_profile.email,
        COALESCE(user_profile.client_id::text, 'NULL')
      )
    END;

  -- Vérifier l'association
  IF user_profile IS NOT NULL AND user_profile.client_id IS NOT NULL THEN
    RAISE NOTICE 'Association correcte: %',
      CASE 
        WHEN user_profile.client_id = redspher_client.id THEN 'OUI'
        ELSE format('NON (client_id attendu=%s, actuel=%s)', 
          redspher_client.id,
          user_profile.client_id
        )
      END;
  ELSE
    RAISE NOTICE 'Association manquante: l''utilisateur n''a pas de client_id';
  END IF;
END $$;