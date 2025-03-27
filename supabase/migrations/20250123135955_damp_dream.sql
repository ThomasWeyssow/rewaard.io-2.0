-- Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Les utilisateurs authentifiés peuvent attribuer des badges" ON profile_badges;

-- Créer une nouvelle politique plus permissive pour l'ajout de badges
CREATE POLICY "Les utilisateurs peuvent gérer les badges"
  ON profile_badges FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);