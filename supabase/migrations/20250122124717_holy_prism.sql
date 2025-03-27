-- Création de la table nomination_areas
CREATE TABLE nomination_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  area_title text NOT NULL,
  area_description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Activation de RLS
ALTER TABLE nomination_areas ENABLE ROW LEVEL SECURITY;

-- Politiques de sécurité
CREATE POLICY "Les utilisateurs authentifiés peuvent lire les nomination areas"
  ON nomination_areas FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Les utilisateurs authentifiés peuvent créer des nomination areas"
  ON nomination_areas FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Les utilisateurs authentifiés peuvent supprimer leurs nomination areas"
  ON nomination_areas FOR DELETE
  TO authenticated
  USING (true);

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER update_nomination_areas_updated_at
  BEFORE UPDATE ON nomination_areas
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();