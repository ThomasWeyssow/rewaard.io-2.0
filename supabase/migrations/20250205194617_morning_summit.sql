-- Drop any existing unique constraints on nominations
ALTER TABLE nominations
DROP CONSTRAINT IF EXISTS nominations_voter_cycle_unique;

-- Drop any existing foreign key constraints
ALTER TABLE nominations
DROP CONSTRAINT IF EXISTS nominations_cycle_id_fkey;

-- Add back the foreign key constraint with ON DELETE SET NULL
ALTER TABLE nominations
ADD CONSTRAINT nominations_cycle_id_fkey 
FOREIGN KEY (cycle_id) 
REFERENCES nomination_cycles(id) 
ON DELETE SET NULL;

-- Add logging to set_nomination_cycle_id function
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
  RAISE NOTICE '- Ongoing start date: %', settings_record.ongoing_nomination_start_date;
  RAISE NOTICE '- Ongoing end date: %', settings_record.ongoing_nomination_end_date;
  RAISE NOTICE '- Input data:';
  RAISE NOTICE '  * voter_id: %', NEW.voter_id;
  RAISE NOTICE '  * nominee_id: %', NEW.nominee_id;
  RAISE NOTICE '  * selected_areas: %', NEW.selected_areas;
  
  -- Set cycle data
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  NEW.nomination_cycle_start := settings_record.ongoing_nomination_start_date;
  NEW.nomination_cycle_end := settings_record.ongoing_nomination_end_date;
  
  -- Log final values
  RAISE NOTICE 'Final nomination values:';
  RAISE NOTICE '- cycle_id: %', NEW.cycle_id;
  RAISE NOTICE '- cycle_start: %', NEW.nomination_cycle_start;
  RAISE NOTICE '- cycle_end: %', NEW.nomination_cycle_end;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop all existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;
DROP POLICY IF EXISTS "allow_all_nominations" ON nominations;

-- Create super simple policy
CREATE POLICY "allow_all_nominations"
  ON nominations FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Verify current settings state
SELECT 
  'Settings state:' as info,
  ongoing_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end
FROM settings;

-- Check for any remaining constraints
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'nominations'::regclass;