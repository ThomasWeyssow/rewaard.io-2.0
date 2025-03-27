/*
  # Add settings table

  1. New Tables
    - `settings`
      - `id` (uuid, primary key)
      - `nomination_period` (text)
      - `nomination_start_date` (date)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
  2. Security
    - Enable RLS on `settings` table
    - Add policy for authenticated users to read settings
    - Add policy for authenticated users to update settings
*/

CREATE TABLE settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nomination_period text NOT NULL CHECK (nomination_period IN ('monthly', 'bi-monthly')),
  nomination_start_date date NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Les utilisateurs authentifiés peuvent lire les paramètres"
  ON settings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Les utilisateurs authentifiés peuvent modifier les paramètres"
  ON settings FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Les utilisateurs authentifiés peuvent créer des paramètres"
  ON settings FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER update_settings_updated_at
  BEFORE UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Insérer les paramètres par défaut
INSERT INTO settings (nomination_period, nomination_start_date)
VALUES ('monthly', CURRENT_DATE);