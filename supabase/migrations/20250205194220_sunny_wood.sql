-- Add more debug logging to set_nomination_cycle_id function
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
  
  -- Set cycle id from settings
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  NEW.nomination_cycle_start := settings_record.ongoing_nomination_start_date;
  NEW.nomination_cycle_end := settings_record.ongoing_nomination_end_date;
  
  -- Log final values
  RAISE NOTICE 'Final nomination values:';
  RAISE NOTICE '- cycle_id: %', NEW.cycle_id;
  RAISE NOTICE '- cycle_start: %', NEW.nomination_cycle_start;
  RAISE NOTICE '- cycle_end: %', NEW.nomination_cycle_end;
  RAISE NOTICE '- voter_id: %', NEW.voter_id;
  RAISE NOTICE '- nominee_id: %', NEW.nominee_id;
  
  -- Verify required fields
  IF NEW.cycle_id IS NULL THEN
    RAISE EXCEPTION 'cycle_id cannot be null';
  END IF;
  
  IF NEW.voter_id IS NULL THEN
    RAISE EXCEPTION 'voter_id cannot be null';
  END IF;
  
  IF NEW.nominee_id IS NULL THEN
    RAISE EXCEPTION 'nominee_id cannot be null';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Verify current settings state
SELECT 
  'Settings state:' as info,
  ongoing_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end
FROM settings;

-- Verify nominations table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'nominations'
ORDER BY ordinal_position;

-- Verify existing nominations
SELECT 
  'Nominations state:' as info,
  COUNT(*) as total_count,
  COUNT(*) FILTER (WHERE cycle_id IS NOT NULL) as with_cycle_id,
  COUNT(*) FILTER (WHERE nomination_cycle_start IS NOT NULL) as with_start_date,
  COUNT(*) FILTER (WHERE nomination_cycle_end IS NOT NULL) as with_end_date
FROM nominations;