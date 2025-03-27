-- Modify column types to timestamptz
ALTER TABLE settings
ALTER COLUMN next_nomination_start_date TYPE timestamptz USING next_nomination_start_date::timestamptz,
ALTER COLUMN next_nomination_end_date TYPE timestamptz USING next_nomination_end_date::timestamptz,
ALTER COLUMN ongoing_nomination_start_date TYPE timestamptz USING ongoing_nomination_start_date::timestamptz,
ALTER COLUMN ongoing_nomination_end_date TYPE timestamptz USING ongoing_nomination_end_date::timestamptz;

-- Reset current cycles to ensure proper date formatting
UPDATE settings 
SET 
  next_nomination_start_date = date_trunc('day', CURRENT_TIMESTAMP + interval '1 day')::timestamptz,
  next_nomination_end_date = NULL,
  ongoing_nomination_start_date = NULL,
  ongoing_nomination_end_date = NULL,
  ongoing_nomination_area_id = NULL
WHERE id IS NOT NULL;

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
  column_types RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  -- Get column types
  SELECT 
    pg_typeof(next_nomination_start_date) as next_start_type,
    pg_typeof(next_nomination_end_date) as next_end_type,
    pg_typeof(ongoing_nomination_start_date) as ongoing_start_type,
    pg_typeof(ongoing_nomination_end_date) as ongoing_end_type
  INTO column_types
  FROM settings
  LIMIT 1;
  
  RAISE NOTICE 'Column types:';
  RAISE NOTICE '- next_nomination_start_date: %', column_types.next_start_type;
  RAISE NOTICE '- next_nomination_end_date: %', column_types.next_end_type;
  RAISE NOTICE '- ongoing_nomination_start_date: %', column_types.ongoing_start_type;
  RAISE NOTICE '- ongoing_nomination_end_date: %', column_types.ongoing_end_type;
  
  RAISE NOTICE 'Current values:';
  RAISE NOTICE '- Next nomination start: %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination end: %', settings_record.next_nomination_end_date;
  RAISE NOTICE '- Ongoing nomination start: %', settings_record.ongoing_nomination_start_date;
  RAISE NOTICE '- Ongoing nomination end: %', settings_record.ongoing_nomination_end_date;
END $$;