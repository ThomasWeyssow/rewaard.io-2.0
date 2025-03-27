-- Modifier la fonction pour gérer correctement la transition
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    -- Clear ongoing cycle
    UPDATE settings
    SET
      ongoing_nomination_start_date = NULL,
      ongoing_nomination_end_date = NULL,
      ongoing_nomination_area_id = NULL,
      ongoing_nomination_period = NULL
    WHERE id = settings_record.id;
    
    -- Refresh settings record
    SELECT * INTO settings_record
    FROM settings
    LIMIT 1;
  END IF;

  -- Now check if we need to start a new cycle
  IF settings_record.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     settings_record.ongoing_nomination_start_date IS NULL THEN
    
    -- Move next cycle to ongoing
    UPDATE settings
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      -- Reset next cycle
      next_nomination_start_date = next_nomination_end_date + interval '1 day',
      next_nomination_end_date = NULL,
      next_nomination_area_id = NULL,
      next_nomination_period = NULL
    WHERE id = settings_record.id;

    RAISE NOTICE 'Nomination cycle updated at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Exécuter la fonction
SELECT check_and_update_nomination_cycles();

-- Vérifier le résultat
SELECT 
  to_char(next_nomination_start_date, 'YYYY-MM-DD HH24:MI:SS') as next_start,
  to_char(next_nomination_end_date, 'YYYY-MM-DD HH24:MI:SS') as next_end,
  to_char(ongoing_nomination_start_date, 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date, 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  next_nomination_period,
  ongoing_nomination_period,
  next_nomination_area_id,
  ongoing_nomination_area_id
FROM settings;