-- Create incentives table if it doesn't exist
CREATE TABLE IF NOT EXISTS incentives (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  icon text NOT NULL DEFAULT 'Award',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create nomination_areas table if it doesn't exist
CREATE TABLE IF NOT EXISTS nomination_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL,
  areas jsonb NOT NULL DEFAULT '[]',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE incentives ENABLE ROW LEVEL SECURITY;
ALTER TABLE nomination_areas ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read incentives" ON incentives;
DROP POLICY IF EXISTS "Anyone can read nomination areas" ON nomination_areas;

-- Create policies
CREATE POLICY "Anyone can read incentives"
  ON incentives FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anyone can read nomination areas"
  ON nomination_areas FOR SELECT
  TO authenticated
  USING (true);

-- Insert default incentives if none exist
INSERT INTO incentives (title, description, icon)
SELECT 'Jour de congé supplémentaire', 'Profitez d''une journée de repos bien méritée', 'Award'
WHERE NOT EXISTS (SELECT 1 FROM incentives);

-- Insert default nomination area if none exist
INSERT INTO nomination_areas (category, areas)
SELECT 
  'Leadership',
  '[
    {"title": "Vision stratégique", "description": "Capacité à définir et communiquer une vision claire"},
    {"title": "Développement d''équipe", "description": "Encourage la croissance et le développement des autres"},
    {"title": "Innovation", "description": "Propose et implémente des solutions créatives"}
  ]'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM nomination_areas);

-- Ensure settings table has at least one record
INSERT INTO settings (nomination_period)
SELECT 'monthly'
WHERE NOT EXISTS (SELECT 1 FROM settings);

-- Ensure page_settings has all required pages
INSERT INTO page_settings (page_name, is_enabled)
VALUES 
  ('hero-program', true),
  ('employees', true),
  ('rewards', true),
  ('voting', true),
  ('review', true),
  ('history', true),
  ('users', true),
  ('settings', true)
ON CONFLICT (page_name) 
DO UPDATE SET is_enabled = EXCLUDED.is_enabled;

-- Log the current state
DO $$
DECLARE
  incentives_count integer;
  areas_count integer;
  settings_count integer;
  pages_count integer;
BEGIN
  SELECT COUNT(*) INTO incentives_count FROM incentives;
  SELECT COUNT(*) INTO areas_count FROM nomination_areas;
  SELECT COUNT(*) INTO settings_count FROM settings;
  SELECT COUNT(*) INTO pages_count FROM page_settings;

  RAISE NOTICE 'Database state:';
  RAISE NOTICE '- Incentives: % records', incentives_count;
  RAISE NOTICE '- Nomination areas: % records', areas_count;
  RAISE NOTICE '- Settings: % records', settings_count;
  RAISE NOTICE '- Page settings: % records', pages_count;
END $$;