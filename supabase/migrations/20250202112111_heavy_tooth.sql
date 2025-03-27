-- Reset both ongoing and next nomination cycles
UPDATE settings
SET 
  -- Reset ongoing cycle
  ongoing_nomination_start_date = NULL,
  ongoing_nomination_end_date = NULL,
  ongoing_nomination_area_id = NULL,
  -- Reset next cycle
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
    ongoing_nomination_area_id,
    nomination_period
  INTO settings_record
  FROM settings
  LIMIT 1;

  -- Log the new state
  RAISE NOTICE 'Nomination cycles reset:';
  RAISE NOTICE '- Next cycle: All fields set to NULL';
  RAISE NOTICE '- Ongoing cycle: All fields set to NULL';
  RAISE NOTICE '- Nomination period: %', settings_record.nomination_period;
END $$;