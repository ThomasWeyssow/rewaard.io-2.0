-- Ajout de la politique pour permettre aux utilisateurs authentifiés de mettre à jour les nomination areas
CREATE POLICY "Les utilisateurs authentifiés peuvent mettre à jour les nomination areas"
  ON nomination_areas FOR UPDATE
  TO authenticated
  USING (true);