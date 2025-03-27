-- Add Admin role to nicolas@gmail.com
DO $$
DECLARE
  user_id uuid;
  admin_role_id uuid;
BEGIN
  -- Get user ID
  SELECT id INTO user_id
  FROM profiles
  WHERE email = 'nicolas@gmail.com';

  -- Get Admin role ID
  SELECT id INTO admin_role_id
  FROM roles
  WHERE name = 'Admin';

  -- Add Admin role if not already assigned
  IF user_id IS NOT NULL AND admin_role_id IS NOT NULL THEN
    INSERT INTO profile_roles (profile_id, role_id)
    VALUES (user_id, admin_role_id)
    ON CONFLICT (profile_id, role_id) DO NOTHING;
  END IF;
END $$;