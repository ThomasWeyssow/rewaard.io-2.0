-- Drop existing function and trigger
DROP FUNCTION IF EXISTS calculate_nomination_dates CASCADE;
DROP TRIGGER IF EXISTS calculate_nomination_dates_trigger ON settings;

-- Recreate settings table with original structure
CREATE TABLE IF NOT EXISTS new_settings (
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
INSERT INTO new_settings (
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
FROM settings;

-- Drop old table and rename new one
DROP TABLE settings;
ALTER TABLE new_settings RENAME TO settings;

-- Recreate RLS policies
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

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