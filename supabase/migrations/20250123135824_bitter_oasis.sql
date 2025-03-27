-- Supprimer l'ancienne politique de mise à jour si elle existe
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leur propre profil" ON profiles;

-- Créer une nouvelle politique plus permissive pour la mise à jour des points
CREATE POLICY "Les utilisateurs peuvent mettre à jour les points"
  ON profiles FOR UPDATE
  TO authenticated
  USING (true);