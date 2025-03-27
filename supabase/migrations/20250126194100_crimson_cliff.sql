-- Drop existing policies
DROP POLICY IF EXISTS "client_select_policy" ON clients;
DROP POLICY IF EXISTS "client_admin_policy" ON clients;
DROP POLICY IF EXISTS "client_modules_select_policy" ON client_modules;
DROP POLICY IF EXISTS "client_modules_admin_policy" ON client_modules;

-- Create new client policies
CREATE POLICY "client_select_policy"
  ON clients FOR SELECT
  TO authenticated
  USING (
    -- Allow access if user has a profile linked to the client
    id IN (
      SELECT client_id 
      FROM profiles 
      WHERE id = auth.uid()
    )
    OR
    -- Or if user is an admin (based on auth.users metadata)
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'department' = 'Admin'
    )
  );

CREATE POLICY "client_admin_policy"
  ON clients FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'department' = 'Admin'
    )
  );

-- Create new client_modules policies
CREATE POLICY "client_modules_select_policy"
  ON client_modules FOR SELECT
  TO authenticated
  USING (
    -- Allow access if user has a profile linked to the client
    client_id IN (
      SELECT client_id 
      FROM profiles 
      WHERE id = auth.uid()
    )
    OR
    -- Or if user is an admin (based on auth.users metadata)
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'department' = 'Admin'
    )
  );

CREATE POLICY "client_modules_admin_policy"
  ON client_modules FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'department' = 'Admin'
    )
  );

-- Update profiles policies to allow admin access
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir tous les profils" ON profiles;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leur propre profil" ON profiles;

CREATE POLICY "profiles_select_policy"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    -- Allow users to see profiles from their client
    client_id IN (
      SELECT client_id 
      FROM profiles 
      WHERE id = auth.uid()
    )
    OR
    -- Or if user is an admin
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'department' = 'Admin'
    )
  );

CREATE POLICY "profiles_update_policy"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    -- Users can update their own profile
    id = auth.uid()
    OR
    -- Or if user is an admin
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'department' = 'Admin'
    )
  );