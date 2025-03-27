-- Drop all existing policies first
DO $$ 
BEGIN
  -- Drop all existing policies on profiles table
  DROP POLICY IF EXISTS "Les utilisateurs peuvent voir tous les profils" ON profiles;
  DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leur propre profil" ON profiles;
  DROP POLICY IF EXISTS "Les utilisateurs peuvent créer leur profil" ON profiles;
  DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
  DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
  DROP POLICY IF EXISTS "allow_all_profiles" ON profiles;
  DROP POLICY IF EXISTS "profiles_select" ON profiles;
  DROP POLICY IF EXISTS "profiles_insert" ON profiles;
  DROP POLICY IF EXISTS "profiles_update" ON profiles;
  DROP POLICY IF EXISTS "profiles_delete" ON profiles;
END $$;

-- Create new policies with unique names
CREATE POLICY "profiles_select_v2"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "profiles_insert_v2"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "profiles_update_v2"
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

CREATE POLICY "profiles_delete_v2"
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