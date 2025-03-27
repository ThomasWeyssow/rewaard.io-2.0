-- Drop existing policies
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir tous les profils" ON profiles;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leur propre profil" ON profiles;
DROP POLICY IF EXISTS "Les utilisateurs peuvent créer leur profil" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "allow_all_profiles" ON profiles;

-- Create new simplified policies
CREATE POLICY "profiles_select"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profiles_insert"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    -- Users can update their own profile
    auth.uid() = id
    OR
    -- Admins can update any profile
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

CREATE POLICY "profiles_delete"
  ON profiles FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );