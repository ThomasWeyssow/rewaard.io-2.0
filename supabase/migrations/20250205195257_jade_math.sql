-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS set_nomination_cycle_id_trigger ON nominations;
DROP FUNCTION IF EXISTS set_nomination_cycle_id;

-- Drop existing table if it exists
DROP TABLE IF EXISTS nominations;

-- Create nominations table with proper structure
CREATE TABLE nominations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  nominee_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  cycle_id uuid REFERENCES nomination_cycles(id) ON DELETE CASCADE,
  selected_areas text[] NOT NULL,
  justification text NOT NULL,
  remarks text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE nominations ENABLE ROW LEVEL SECURITY;

-- Create function to set cycle_id on new nominations
CREATE OR REPLACE FUNCTION set_nomination_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;
  
  -- Log initial state
  RAISE NOTICE 'Starting nomination insert:';
  RAISE NOTICE '- Settings found: %', settings_record IS NOT NULL;
  RAISE NOTICE '- Ongoing cycle ID: %', settings_record.ongoing_cycle_id;
  
  -- Set cycle id from settings
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new nominations
CREATE TRIGGER set_nomination_cycle_id_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION set_nomination_cycle_id();

-- Create simplified policies
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (voter_id = auth.uid());

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_nominations,
  COUNT(DISTINCT cycle_id) as unique_cycles,
  EXISTS (
    SELECT 1 
    FROM settings 
    WHERE ongoing_cycle_id IS NOT NULL
  ) as has_ongoing_cycle
FROM nominations;

-- Log the current settings state
SELECT 
  'Settings state:' as info,
  ongoing_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end
FROM settings;