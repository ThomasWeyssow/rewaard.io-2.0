-- Add more detailed logging to set_nomination_cycle_id function
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
  
  -- Verify settings exist
  IF settings_record IS NULL THEN
    RAISE EXCEPTION 'No settings record found';
  END IF;
  
  -- Verify ongoing cycle exists
  IF settings_record.ongoing_nomination_start_date IS NULL OR 
     settings_record.ongoing_nomination_end_date IS NULL THEN
    RAISE EXCEPTION 'No active nomination cycle found';
  END IF;
  
  -- Generate ongoing_cycle_id if needed
  IF settings_record.ongoing_cycle_id IS NULL THEN
    WITH updated_settings AS (
      UPDATE settings
      SET ongoing_cycle_id = gen_random_uuid()
      WHERE id = settings_record.id
      RETURNING ongoing_cycle_id
    )
    SELECT ongoing_cycle_id INTO settings_record.ongoing_cycle_id
    FROM updated_settings;
    
    RAISE NOTICE 'Generated new ongoing_cycle_id: %', settings_record.ongoing_cycle_id;
  END IF;
  
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

-- Check for any unique constraints that might block insertion
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'nominations'::regclass;

-- Check for any foreign key constraints
SELECT
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM 
  information_schema.table_constraints AS tc 
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'nominations';

-- Check table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'nominations'
ORDER BY ordinal_position;

-- Verify current settings state
SELECT 
  'Settings state:' as info,
  ongoing_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end
FROM settings;