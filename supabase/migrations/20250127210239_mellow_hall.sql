-- Vérifier l'état actuel
DO $$ 
DECLARE 
  redspher_id uuid;
  user_id uuid;
BEGIN
  -- Get Redspher client ID
  SELECT id INTO redspher_id 
  FROM clients 
  WHERE name = 'Redspher';

  -- Get user ID
  SELECT id INTO user_id
  FROM profiles
  WHERE email = 'nicolas@gmail.com';

  -- Log current state
  RAISE NOTICE 'Current state: redspher_id=%, user_id=%, user_client=%', 
    redspher_id,
    user_id,
    (SELECT client_id FROM profiles WHERE id = user_id);

  -- Update user's client_id if needed
  IF redspher_id IS NOT NULL AND user_id IS NOT NULL THEN
    UPDATE profiles 
    SET client_id = redspher_id
    WHERE id = user_id 
    AND (client_id IS NULL OR client_id != redspher_id);
    
    RAISE NOTICE 'Updated user client_id to %', redspher_id;
  ELSE
    RAISE EXCEPTION 'Missing required data: redspher_id=%, user_id=%', redspher_id, user_id;
  END IF;
END $$;