-- Update the check_and_update_nomination_cycles function to fix cycle transition
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  paris_current_time timestamptz;
BEGIN
  -- Get current time in Paris timezone
  paris_current_time := CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Paris';

  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date AT TIME ZONE 'Europe/Paris' < paris_current_time THEN
    -- Save top 6 nominees before clearing the cycle
    INSERT INTO nomination_results (
      cycle_start_date,
      cycle_end_date,
      nominee_id,
      nomination_count,
      nomination_area_id
    )
    SELECT 
      settings_record.ongoing_nomination_start_date,
      settings_record.ongoing_nomination_end_date,
      n.nominee_id,
      COUNT(DISTINCT n.voter_id) as nomination_count,
      settings_record.ongoing_nomination_area_id
    FROM nominations n
    WHERE 
      n.nomination_cycle_start = settings_record.ongoing_nomination_start_date AND
      n.nomination_cycle_end = settings_record.ongoing_nomination_end_date
    GROUP BY n.nominee_id
    ORDER BY 
      COUNT(DISTINCT n.voter_id) DESC
    LIMIT 6;

    -- Clear ongoing cycle
    UPDATE settings
    SET
      ongoing_nomination_start_date = NULL,
      ongoing_nomination_end_date = NULL,
      ongoing_nomination_area_id = NULL,
      ongoing_nomination_period = NULL
    WHERE id = settings_record.id
    RETURNING * INTO settings_record; -- Get updated settings immediately
  END IF;

  -- Only check for new cycle if there is no ongoing cycle
  -- This prevents the issue where a new cycle would start immediately after clearing the ongoing one
  IF settings_record.ongoing_nomination_start_date IS NULL AND
     settings_record.next_nomination_start_date AT TIME ZONE 'Europe/Paris' <= paris_current_time THEN
    
    -- Move next cycle to ongoing
    UPDATE settings
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      -- Set next cycle to start at midnight the day after ongoing cycle ends
      next_nomination_start_date = date_trunc('day', next_nomination_end_date AT TIME ZONE 'Europe/Paris' + interval '1 day')::timestamptz,
      next_nomination_area_id = NULL,
      next_nomination_period = NULL,
      next_nomination_end_date = NULL
    WHERE id = settings_record.id;

    RAISE NOTICE 'Nomination cycle updated at %', paris_current_time;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Exécuter la fonction avec la correction
SELECT check_and_update_nomination_cycles();

-- Vérifier l'état des cycles
WITH cycle_state AS (
  SELECT 
    to_char(next_nomination_start_date AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_start,
    to_char(next_nomination_end_date AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_end,
    to_char(ongoing_nomination_start_date AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
    to_char(ongoing_nomination_end_date AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
    next_nomination_period,
    ongoing_nomination_period,
    next_nomination_area_id,
    ongoing_nomination_area_id,
    CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Paris' as current_time,
    next_nomination_start_date AT TIME ZONE 'Europe/Paris' <= CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Paris' as should_start_new_cycle,
    ongoing_nomination_start_date IS NULL as no_ongoing_cycle,
    CASE 
      WHEN ongoing_nomination_end_date IS NOT NULL 
      THEN ongoing_nomination_end_date AT TIME ZONE 'Europe/Paris' < CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Paris'
      ELSE false 
    END as ongoing_cycle_finished
  FROM settings
)
SELECT 
  'État des cycles de nomination:' as info,
  next_start as "Prochain cycle - Début",
  next_end as "Prochain cycle - Fin",
  ongoing_start as "Cycle en cours - Début",
  ongoing_end as "Cycle en cours - Fin",
  next_nomination_period as "Période - Prochain",
  ongoing_nomination_period as "Période - En cours",
  next_nomination_area_id as "Zone - Prochain",
  ongoing_nomination_area_id as "Zone - En cours",
  to_char(current_time, 'YYYY-MM-DD HH24:MI:SS') as "Heure actuelle",
  should_start_new_cycle as "Démarrer nouveau cycle ?",
  no_ongoing_cycle as "Pas de cycle en cours ?",
  ongoing_cycle_finished as "Cycle en cours terminé ?"
FROM cycle_state;