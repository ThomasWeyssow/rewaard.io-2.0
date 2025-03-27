-- Create modules table
CREATE TABLE modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create module_pages junction table
CREATE TABLE module_pages (
  module_id uuid REFERENCES modules(id) ON DELETE CASCADE,
  page_name text REFERENCES page_settings(page_name) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (module_id, page_name)
);

-- Enable RLS
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_pages ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can read modules"
  ON modules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can manage modules"
  ON modules FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

CREATE POLICY "Anyone can read module pages"
  ON module_pages FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can manage module pages"
  ON module_pages FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Add trigger for updating timestamps
CREATE TRIGGER update_modules_updated_at
  BEFORE UPDATE ON modules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Insert default modules
INSERT INTO modules (name, description)
VALUES 
  ('Rewards', 'Système de récompenses et de points'),
  ('Hero Program', 'Programme de nomination des employés du mois');

-- Associate pages with modules
INSERT INTO module_pages (module_id, page_name)
SELECT 
  m.id,
  unnest(CASE 
    WHEN m.name = 'Rewards' THEN 
      ARRAY['employees', 'rewards']::text[]
    ELSE 
      ARRAY['hero-program', 'voting', 'review', 'history', 'users', 'settings']::text[]
  END) as page_name
FROM modules m;