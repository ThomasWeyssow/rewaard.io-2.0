/*
  # Schéma initial pour l'application de récompenses employés

  1. Tables
    - `profiles`
      - `id` (uuid, clé primaire)
      - `email` (text)
      - `name` (text)
      - `avatar_url` (text)
      - `department` (text)
      - `points` (integer)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

    - `badges`
      - `id` (uuid, clé primaire)
      - `name` (text)
      - `icon` (text)
      - `description` (text)
      - `color` (text)
      - `created_at` (timestamp)

    - `profile_badges`
      - `profile_id` (uuid, référence profiles)
      - `badge_id` (uuid, référence badges)
      - `created_at` (timestamp)

    - `rewards`
      - `id` (uuid, clé primaire)
      - `name` (text)
      - `description` (text)
      - `points_cost` (integer)
      - `image_url` (text)
      - `created_at` (timestamp)

    - `votes`
      - `id` (uuid, clé primaire)
      - `voter_id` (uuid, référence profiles)
      - `voted_for_id` (uuid, référence profiles)
      - `month` (integer)
      - `year` (integer)
      - `created_at` (timestamp)

  2. Sécurité
    - RLS activé sur toutes les tables
    - Politiques pour lecture/écriture basées sur l'authentification
*/

-- Création de la table profiles
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  name text NOT NULL,
  avatar_url text,
  department text,
  points integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Les utilisateurs peuvent voir tous les profils"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Les utilisateurs peuvent modifier leur propre profil"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Les utilisateurs peuvent créer leur profil"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Création de la table badges
CREATE TABLE badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  icon text NOT NULL,
  description text,
  color text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tout le monde peut voir les badges"
  ON badges FOR SELECT
  TO authenticated
  USING (true);

-- Création de la table profile_badges
CREATE TABLE profile_badges (
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id uuid REFERENCES badges(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (profile_id, badge_id)
);

ALTER TABLE profile_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Les utilisateurs peuvent voir tous les badges attribués"
  ON profile_badges FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Seuls les admins peuvent attribuer des badges"
  ON profile_badges FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND department = 'Admin'
    )
  );

-- Création de la table rewards
CREATE TABLE rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  points_cost integer NOT NULL,
  image_url text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tout le monde peut voir les récompenses"
  ON rewards FOR SELECT
  TO authenticated
  USING (true);

-- Création de la table votes
CREATE TABLE votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  voted_for_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  month integer NOT NULL,
  year integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE (voter_id, month, year)
);

ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Les utilisateurs peuvent voir tous les votes"
  ON votes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Les utilisateurs peuvent voter"
  ON votes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = voter_id);

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour updated_at sur profiles
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Index pour améliorer les performances
CREATE INDEX idx_votes_month_year ON votes(month, year);
CREATE INDEX idx_profile_badges_profile_id ON profile_badges(profile_id);
CREATE INDEX idx_votes_voted_for_id ON votes(voted_for_id);