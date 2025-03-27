/*
  # Ajout de la structure pour les clients

  1. Nouvelles Tables
    - `clients`
      - `id` (uuid, primary key)
      - `name` (text, non null)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Modifications
    - Ajout de la colonne `client_id` à la table `profiles`
    - Ajout de la contrainte de clé étrangère vers `clients`

  3. Sécurité
    - Enable RLS sur la table `clients`
    - Politiques de sécurité pour la lecture des clients
    - Politiques de sécurité pour la gestion des clients (admin uniquement)
*/

-- Create clients table
CREATE TABLE clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add client_id to profiles
ALTER TABLE profiles
ADD COLUMN client_id uuid REFERENCES clients(id);

-- Enable RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Create policies for clients
CREATE POLICY "Users can read clients they belong to"
  ON clients FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT client_id 
      FROM profiles 
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage clients"
  ON clients FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  );

-- Create trigger for updating timestamps
CREATE TRIGGER update_clients_updated_at
  BEFORE UPDATE ON clients
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Insert Redspher client
INSERT INTO clients (name) 
VALUES ('Redspher');

-- Update existing profiles to belong to Redspher
UPDATE profiles 
SET client_id = (SELECT id FROM clients WHERE name = 'Redspher')
WHERE client_id IS NULL;

-- Make client_id NOT NULL after data migration
ALTER TABLE profiles
ALTER COLUMN client_id SET NOT NULL;

-- Add index for better performance
CREATE INDEX idx_profiles_client_id ON profiles(client_id);