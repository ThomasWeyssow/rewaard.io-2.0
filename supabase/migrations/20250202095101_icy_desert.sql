-- Create temporary table to store existing data
CREATE TABLE temp_settings AS SELECT * FROM settings;

-- Drop existing table
DROP TABLE settings CASCADE;

-- Recreate settings table with correct column types
CREATE TABLE settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nomination_period text NOT NULL CHECK (nomination_period IN ('monthly', 'bi-monthly', '3-minutes')),
  next_nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL,
  next_nomination_start_date timestamptz,
  next_nomination_end_date timestamptz,
  ongoing_nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL,
  ongoing_nomination_start_date timestamptz,
  ongoing_nomination_end_date timestamptz,
  hero_banner_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Copy data back
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
  nomination_period,
  next_nomination_area_id,
  next_nomination_start_date::timestamptz,
  next_nomination_end_date::timestamptz,
  ongoing_nomination_area_id,
  ongoing_nomination_start_date::timestamptz,
  ongoing_nomination_end_date::timestamptz,
  hero_banner_url,
  created_at,
  updated_at
FROM temp_settings;

-- Drop temporary table
DROP TABLE temp_settings;

-- Enable RLS
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Create policies
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