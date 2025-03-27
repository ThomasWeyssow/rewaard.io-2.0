/*
  # Mise à jour des politiques pour la gestion des emails

  1. Changements
    - Ajout d'une politique pour la mise à jour des emails
    - Ajout d'un trigger pour vérifier l'unicité des emails
    - Suppression de l'ancienne politique de mise à jour

  2. Sécurité
    - Vérification de l'unicité des emails
    - Protection contre les doublons
    - Restriction des mises à jour aux propriétaires des profils
*/

-- Supprimer l'ancienne politique de mise à jour si elle existe
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leur propre profil" ON profiles;

-- Créer une nouvelle politique plus précise pour la mise à jour des profils
CREATE POLICY "Les utilisateurs peuvent modifier leur propre profil"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Fonction pour vérifier l'unicité de l'email
CREATE OR REPLACE FUNCTION check_email_unique()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM profiles
    WHERE email = NEW.email
    AND id != NEW.id
  ) THEN
    RAISE EXCEPTION 'Cet email est déjà utilisé';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS ensure_email_unique ON profiles;

-- Créer le trigger pour vérifier l'unicité de l'email
CREATE TRIGGER ensure_email_unique
  BEFORE INSERT OR UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION check_email_unique();