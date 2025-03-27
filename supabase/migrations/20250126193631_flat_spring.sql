-- Delete nominations for Sarah Weyssow
DELETE FROM nominations
WHERE nominee_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'sarah.weyssow@company.com'
);

-- Delete nomination validations for Sarah Weyssow
DELETE FROM nomination_validations
WHERE nominee_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'sarah.weyssow@company.com'
);