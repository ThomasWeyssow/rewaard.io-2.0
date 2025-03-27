-- Delete all nominations where Sarah is either the voter or nominee
DELETE FROM nominations
WHERE voter_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'sarah.weyssow@company.com'
)
OR nominee_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'sarah.weyssow@company.com'
);

-- Delete all nomination validations where Sarah is either the validator or nominee
DELETE FROM nomination_validations
WHERE validator_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'sarah.weyssow@company.com'
)
OR nominee_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'sarah.weyssow@company.com'
);

-- Delete all votes where Sarah is either the voter or voted for
DELETE FROM votes
WHERE voter_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'sarah.weyssow@company.com'
)
OR voted_for_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'sarah.weyssow@company.com'
);