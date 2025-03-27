-- Add ExCom role to nicolas@gmail.com
WITH user_id AS (
  SELECT id FROM profiles WHERE email = 'nicolas@gmail.com'
),
excom_role_id AS (
  SELECT id FROM roles WHERE name = 'ExCom'
)
INSERT INTO profile_roles (profile_id, role_id)
SELECT 
  user_id.id,
  excom_role_id.id
FROM user_id, excom_role_id
ON CONFLICT DO NOTHING;