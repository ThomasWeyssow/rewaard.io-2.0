-- Ajout de la politique pour permettre aux utilisateurs authentifiés de mettre à jour les incentives
CREATE POLICY "Les utilisateurs authentifiés peuvent mettre à jour les incentives"
  ON incentives FOR UPDATE
  TO authenticated
  USING (true);