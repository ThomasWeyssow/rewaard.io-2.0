/*
  # Ajout de la table incentives

  1. Nouvelle Table
    - `incentives`
      - `id` (uuid, primary key)
      - `title` (text, non null)
      - `description` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Sécurité
    - Enable RLS sur la table `incentives`
    - Ajout de politiques pour:
      - Lecture par les utilisateurs authentifiés
      - Création par les utilisateurs authentifiés
      - Suppression par les utilisateurs authentifiés
*/

-- Création de la table incentives
CREATE TABLE incentives (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Activation de RLS
ALTER TABLE incentives ENABLE ROW LEVEL SECURITY;

-- Politiques de sécurité
CREATE POLICY "Les utilisateurs authentifiés peuvent lire les incentives"
  ON incentives FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Les utilisateurs authentifiés peuvent créer des incentives"
  ON incentives FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Les utilisateurs authentifiés peuvent supprimer leurs incentives"
  ON incentives FOR DELETE
  TO authenticated
  USING (true);

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER update_incentives_updated_at
  BEFORE UPDATE ON incentives
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();