-- Reset next nomination cycle fields to NULL
UPDATE settings
SET 
  next_nomination_start_date = NULL,
  next_nomination_end_date = NULL,
  next_nomination_area_id = NULL
WHERE id IS NOT NULL;

-- Log the update
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get updated settings
  SELECT 
    next_nomination_start_date,
    next_nomination_end_date,
    next_nomination_area_id,
    ongoing_nomination_start_date,
    ongoing_nomination_end_date,
    ongoing_nomination_area_id
  INTO settings_record
  FROM settings
  LIMIT 1;

  -- Log the new state
  RAISE NOTICE 'Updated nomination cycles state:';
  RAISE NOTICE 'Next cycle: All fields set to NULL';
  RAISE NOTICE 'Ongoing cycle remains unchanged:';
  RAISE NOTICE '- Start: %', settings_record.ongoing_nomination_start_date;
  RAISE NOTICE '- End: %', settings_record.ongoing_nomination_end_date;
  RAISE NOTICE '- Area ID: %', settings_record.ongoing_nomination_area_id;
END $$;