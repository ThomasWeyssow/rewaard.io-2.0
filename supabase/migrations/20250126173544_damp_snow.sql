-- Create modules table
CREATE TABLE modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text NOT NULL,
  features text[] NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create client_modules junction table
CREATE TABLE client_modules (
  client_id uuid REFERENCES clients(id) ON DELETE CASCADE,
  module_id uuid REFERENCES modules(id) ON DELETE CASCADE,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (client_id, module_id)
);

-- Enable RLS
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_modules ENABLE ROW LEVEL SECURITY;

-- Create policies for modules
CREATE POLICY "Users can read modules"
  ON modules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage modules"
  ON modules FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  );

-- Create policies for client_modules
CREATE POLICY "Users can read their client's modules"
  ON client_modules FOR SELECT
  TO authenticated
  USING (
    client_id IN (
      SELECT client_id 
      FROM profiles 
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage client modules"
  ON client_modules FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  );

-- Insert default modules
INSERT INTO modules (name, description, features) VALUES
  (
    'employee-rewards',
    'Système de récompenses pour les employés',
    ARRAY['Liste des employés', 'Gestion des récompenses', 'Attribution de points']
  ),
  (
    'employee-of-the-month',
    'Programme de nomination des employés du mois',
    ARRAY['Hero Program', 'Nominations', 'Validation ExCom', 'Wall of Fame', 'Gestion des utilisateurs', 'Paramètres']
  );

-- Activate both modules for Redspher by default
INSERT INTO client_modules (client_id, module_id)
SELECT 
  c.id as client_id,
  m.id as module_id
FROM clients c
CROSS JOIN modules m
WHERE c.name = 'Redspher';

-- Add indexes for better performance
CREATE INDEX idx_client_modules_client_id ON client_modules(client_id);
CREATE INDEX idx_client_modules_module_id ON client_modules(module_id);