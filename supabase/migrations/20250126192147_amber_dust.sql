-- Delete nomination for Nicolas Devaux
DELETE FROM nominations
WHERE voter_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'nicolas@gmail.com'
);

-- Delete nomination validations for Nicolas Devaux
DELETE FROM nomination_validations
WHERE validator_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'nicolas@gmail.com'
);