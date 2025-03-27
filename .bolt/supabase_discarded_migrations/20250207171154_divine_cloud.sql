-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- Create base tables
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  department text,
  points integer DEFAULT 0,
  avatar_url text,
  client_id uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL CHECK (name IN ('User', 'ExCom', 'Admin')),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE profile_roles (
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  role_id uuid REFERENCES roles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (profile_id, role_id)
);

CREATE TABLE clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create feature management tables
CREATE TABLE page_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  page_name text UNIQUE NOT NULL,
  is_enabled boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create nomination system tables
CREATE TABLE nomination_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL,
  areas jsonb NOT NULL DEFAULT '[]',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE incentives (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  icon text NOT NULL DEFAULT 'Award',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE nomination_cycles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL,
  period text NOT NULL CHECK (period IN ('monthly', 'bi-monthly')),
  nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL,
  status text NOT NULL CHECK (status IN ('next', 'ongoing', 'completed')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  next_nomination_start_date timestamptz,
  next_nomination_end_date timestamptz,
  next_nomination_period text CHECK (next_nomination_period IN ('monthly', 'bi-monthly')),
  next_nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL,
  ongoing_nomination_start_date timestamptz,
  ongoing_nomination_end_date timestamptz,
  ongoing_nomination_period text CHECK (ongoing_nomination_period IN ('monthly', 'bi-monthly')),
  ongoing_nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL,
  ongoing_cycle_id uuid,
  hero_banner_url text DEFAULT 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=1920&h=300&fit=crop',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE nominations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  nominee_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  selected_areas text[] NOT NULL,
  justification text NOT NULL,
  remarks text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE nomination_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id uuid REFERENCES nomination_cycles(id) ON DELETE CASCADE,
  voter_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  nominee_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  selected_areas text[] NOT NULL,
  justification text NOT NULL,
  remarks text,
  nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE nomination_validations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  validator_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  nominee_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT unique_validator_nominee UNIQUE (validator_id, nominee_id)
);

-- Create indexes
CREATE INDEX idx_profiles_client_id ON profiles(client_id);
CREATE INDEX idx_profile_roles_profile_role ON profile_roles(profile_id, role_id);
CREATE INDEX idx_nominations_voter_id ON nominations(voter_id);
CREATE INDEX idx_nominations_nominee_id ON nominations(nominee_id);
CREATE INDEX idx_nomination_history_cycle_id ON nomination_history(cycle_id);
CREATE INDEX idx_nomination_validations_nominee ON nomination_validations(nominee_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create nomination cycle management function
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  nominations_to_archive integer;
  completed_cycle_id uuid;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    IF settings_record.ongoing_nomination_start_date IS NOT NULL AND 
       settings_record.ongoing_nomination_end_date IS NOT NULL THEN
      -- Create completed cycle entry
      INSERT INTO nomination_cycles (
        start_date, end_date, period, nomination_area_id, status
      ) VALUES (
        settings_record.ongoing_nomination_start_date,
        settings_record.ongoing_nomination_end_date,
        settings_record.ongoing_nomination_period,
        settings_record.ongoing_nomination_area_id,
        'completed'
      ) RETURNING id INTO completed_cycle_id;

      -- Archive nominations
      SELECT COUNT(*) INTO nominations_to_archive FROM nominations;
      IF nominations_to_archive > 0 THEN
        INSERT INTO nomination_history (
          cycle_id, voter_id, nominee_id, selected_areas, justification, remarks, nomination_area_id
        )
        SELECT 
          completed_cycle_id,
          n.voter_id,
          n.nominee_id,
          n.selected_areas,
          n.justification,
          n.remarks,
          settings_record.ongoing_nomination_area_id
        FROM nominations n;
        TRUNCATE nominations;
      END IF;
    END IF;

    -- Clear ongoing cycle
    UPDATE settings SET
      ongoing_nomination_start_date = NULL,
      ongoing_nomination_end_date = NULL,
      ongoing_nomination_area_id = NULL,
      ongoing_nomination_period = NULL,
      ongoing_cycle_id = NULL
    WHERE id = settings_record.id;
    
    SELECT * INTO settings_record FROM settings LIMIT 1;
  END IF;

  -- Start new cycle if needed
  IF settings_record.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     settings_record.ongoing_nomination_start_date IS NULL THEN
    WITH new_cycle AS (SELECT gen_random_uuid() as id)
    UPDATE settings s SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      ongoing_cycle_id = nc.id,
      next_nomination_start_date = date_trunc('day', next_nomination_end_date + interval '1 day')::timestamptz + interval '23 hours',
      next_nomination_area_id = NULL,
      next_nomination_period = 'monthly',
      next_nomination_end_date = NULL
    FROM new_cycle nc
    WHERE s.id = settings_record.id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DO $$ 
DECLARE
  table_name text;
BEGIN
  FOR table_name IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename IN (
      'profiles', 'clients', 'page_settings', 'nomination_areas',
      'incentives', 'nomination_cycles', 'settings', 'nominations',
      'nomination_validations'
    )
  LOOP
    EXECUTE format('
      CREATE TRIGGER update_%I_updated_at
      BEFORE UPDATE ON %I
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at();
    ', table_name, table_name);
  END LOOP;
END $$;

-- Enable RLS
DO $$ 
DECLARE
  table_name text;
BEGIN
  FOR table_name IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', table_name);
  END LOOP;
END $$;

-- Create RLS policies
CREATE POLICY "profiles_select" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id OR EXISTS (SELECT 1 FROM profile_roles pr JOIN roles r ON r.id = pr.role_id WHERE pr.profile_id = auth.uid() AND r.name = 'Admin'));

CREATE POLICY "roles_select" ON roles FOR SELECT TO authenticated USING (true);

CREATE POLICY "profile_roles_select" ON profile_roles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profile_roles_insert" ON profile_roles FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "profile_roles_delete" ON profile_roles FOR DELETE TO authenticated USING (true);

CREATE POLICY "clients_select" ON clients FOR SELECT TO authenticated USING (true);
CREATE POLICY "clients_admin" ON clients FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM profile_roles pr JOIN roles r ON r.id = pr.role_id WHERE pr.profile_id = auth.uid() AND r.name = 'Admin'));

CREATE POLICY "page_settings_select" ON page_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "page_settings_admin" ON page_settings FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM profile_roles pr JOIN roles r ON r.id = pr.role_id WHERE pr.profile_id = auth.uid() AND r.name = 'Admin'));

CREATE POLICY "nomination_areas_select" ON nomination_areas FOR SELECT TO authenticated USING (true);
CREATE POLICY "incentives_select" ON incentives FOR SELECT TO authenticated USING (true);
CREATE POLICY "nomination_cycles_select" ON nomination_cycles FOR SELECT TO authenticated USING (true);
CREATE POLICY "settings_select" ON settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "nomination_history_select" ON nomination_history FOR SELECT TO authenticated USING (true);

CREATE POLICY "allow_all_nominations" ON nominations FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "validations_select" ON nomination_validations FOR SELECT TO authenticated USING (true);
CREATE POLICY "validations_insert" ON nomination_validations FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM profile_roles pr JOIN roles r ON r.id = pr.role_id WHERE pr.profile_id = auth.uid() AND r.name = 'ExCom'));
CREATE POLICY "validations_delete" ON nomination_validations FOR DELETE TO authenticated USING (validator_id = auth.uid());

-- Schedule cron job
SELECT cron.schedule(
  'check-nomination-cycles',
  '1 23 * * *',
  'SELECT check_and_update_nomination_cycles()'
);

-- Insert default data
INSERT INTO roles (name) VALUES
  ('User'),
  ('ExCom'),
  ('Admin')
ON CONFLICT (name) DO NOTHING;

INSERT INTO page_settings (page_name, is_enabled) VALUES 
  ('hero-program', true),
  ('employees', true),
  ('rewards', true),
  ('voting', true),
  ('review', true),
  ('history', true),
  ('users', true),
  ('settings', true)
ON CONFLICT (page_name) DO NOTHING;