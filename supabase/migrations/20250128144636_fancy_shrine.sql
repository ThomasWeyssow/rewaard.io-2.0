/*
  # Create page settings table

  1. New Tables
    - `page_settings`
      - `id` (uuid, primary key)
      - `page_name` (text, not null)
      - `is_enabled` (boolean, default true)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS
    - Add policies for read/write access
*/

-- Create page_settings table
CREATE TABLE page_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  page_name text NOT NULL,
  is_enabled boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add unique constraint on page_name
CREATE UNIQUE INDEX page_settings_page_name_idx ON page_settings(page_name);

-- Enable RLS
ALTER TABLE page_settings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can read page settings"
  ON page_settings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can modify page settings"
  ON page_settings FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Add trigger for updating timestamps
CREATE TRIGGER update_page_settings_updated_at
  BEFORE UPDATE ON page_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Insert default values for all available pages
INSERT INTO page_settings (page_name, is_enabled)
VALUES 
  ('hero-program', true),
  ('employees', true),
  ('rewards', true),
  ('voting', true),
  ('review', true),
  ('history', true),
  ('users', true),
  ('settings', true);