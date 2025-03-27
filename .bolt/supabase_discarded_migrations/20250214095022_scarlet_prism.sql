-- Clear nominations table
TRUNCATE nominations;

-- Clear nomination validations
TRUNCATE nomination_validations;

-- Reset ongoing cycle in settings
UPDATE settings
SET
  ongoing_nomination_start_date = NULL,
  ongoing_nomination_end_date = NULL,
  ongoing_nomination_area_id = NULL,
  ongoing_nomination_period = NULL,
  ongoing_cycle_id = NULL;

-- Log the cleanup
DO $$
BEGIN
  RAISE NOTICE 'Preview session cache cleared at %', CURRENT_TIMESTAMP;
END $$;