-- Drop existing policies
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "client_select_policy" ON clients;
DROP POLICY IF EXISTS "client_admin_policy" ON clients;
DROP POLICY IF EXISTS "client_modules_select_policy" ON client_modules;
DROP POLICY IF EXISTS "client_modules_admin_policy" ON client_modules;

-- Create simplified policies for profiles
CREATE POLICY "profiles_select_policy"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profiles_update_policy"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'department' = 'Admin'
    )
  );

-- Create simplified policies for clients
CREATE POLICY "client_select_policy"
  ON clients FOR SELECT
  TO authenticated
  USING (true);

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

-- Create simplified policies for client_modules
CREATE POLICY "client_modules_select_policy"
  ON client_modules FOR SELECT
  TO authenticated
  USING (true);

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