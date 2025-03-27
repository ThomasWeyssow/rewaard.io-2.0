-- Add Admin role to nicolas@gmail.com
WITH user_id AS (
  SELECT id FROM profiles WHERE email = 'nicolas@gmail.com'
),
admin_role_id AS (
  SELECT id FROM roles WHERE name = 'Admin'
)
INSERT INTO profile_roles (profile_id, role_id)
SELECT 
  user_id.id,
  admin_role_id.id
FROM user_id, admin_role_id
ON CONFLICT DO NOTHING;