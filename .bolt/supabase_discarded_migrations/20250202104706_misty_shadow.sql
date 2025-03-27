-- Drop existing policies if they exist
DROP POLICY IF EXISTS "settings_select_policy" ON settings;
DROP POLICY IF EXISTS "settings_update_policy" ON settings;
DROP POLICY IF EXISTS "settings_insert_policy" ON settings;
DROP POLICY IF EXISTS "Anyone can read settings" ON settings;
DROP POLICY IF EXISTS "Only admins can modify settings" ON settings;

-- Create temporary table to store existing data
CREATE TABLE temp_settings AS SELECT * FROM settings;

-- Drop existing table and function
DROP TABLE settings CASCADE;
DROP FUNCTION IF EXISTS calculate_nomination_dates CASCADE;

-- Recreate settings table with original structure
CREATE TABLE settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nomination_period text NOT NULL CHECK (nomination_period IN ('monthly', 'bi-monthly')),
  next_nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL,
  next_nomination_start_date date,
  next_nomination_end_date date,
  ongoing_nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL,
  ongoing_nomination_start_date date,
  ongoing_nomination_end_date date,
  hero_banner_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Copy data with date conversion
INSERT INTO settings (
  id,
  nomination_period,
  next_nomination_area_id,
  next_nomination_start_date,
  next_nomination_end_date,
  ongoing_nomination_area_id,
  ongoing_nomination_start_date,
  ongoing_nomination_end_date,
  hero_banner_url,
  created_at,
  updated_at
)
SELECT
  id,
  CASE 
    WHEN nomination_period = '3-minutes' THEN 'monthly'
    ELSE nomination_period
  END,
  next_nomination_area_id,
  next_nomination_start_date::date,
  next_nomination_end_date::date,
  ongoing_nomination_area_id,
  ongoing_nomination_start_date::date,
  ongoing_nomination_end_date::date,
  hero_banner_url,
  created_at,
  updated_at
FROM temp_settings;

-- Drop temporary table
DROP TABLE temp_settings;

-- Enable RLS
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Create new policies
CREATE POLICY "settings_select_policy"
  ON settings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "settings_update_policy"
  ON settings FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

CREATE POLICY "settings_insert_policy"
  ON settings FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Add trigger for updating timestamps
CREATE TRIGGER update_settings_updated_at
  BEFORE UPDATE ON settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();