-- Vérifier l'état actuel du cycle et des nominations
WITH cycle_check AS (
  SELECT 
    s.ongoing_nomination_start_date,
    s.ongoing_nomination_end_date,
    s.ongoing_nomination_period,
    s.ongoing_nomination_area_id,
    s.ongoing_cycle_id,
    CURRENT_TIMESTAMP as current_time,
    s.ongoing_nomination_end_date < CURRENT_TIMESTAMP as should_close
  FROM settings s
),
nomination_check AS (
  SELECT 
    COUNT(*) as total_nominations,
    COUNT(*) FILTER (WHERE cycle_id IS NOT NULL) as nominations_with_cycle
  FROM nominations
)
SELECT 
  'État actuel:' as section,
  cc.*,
  nc.*
FROM cycle_check cc
CROSS JOIN nomination_check nc;

-- Mettre à jour la fonction check_and_update_nomination_cycles
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  completed_cycle_id uuid;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    -- Only create cycle entry when it's completed
    IF settings_record.ongoing_nomination_start_date IS NOT NULL AND 
       settings_record.ongoing_nomination_end_date IS NOT NULL THEN
      -- Create completed cycle entry
      INSERT INTO nomination_cycles (
        start_date,
        end_date,
        period,
        nomination_area_id,
        status
      )
      VALUES (
        settings_record.ongoing_nomination_start_date,
        settings_record.ongoing_nomination_end_date,
        settings_record.ongoing_nomination_period,
        settings_record.ongoing_nomination_area_id,
        'completed'
      )
      RETURNING id INTO completed_cycle_id;

      -- Move nominations to history
      INSERT INTO nomination_history (
        cycle_id,
        voter_id,
        nominee_id,
        selected_areas,
        justification,
        remarks,
        nomination_area_id
      )
      SELECT 
        completed_cycle_id,
        n.voter_id,
        n.nominee_id,
        n.selected_areas,
        n.justification,
        n.remarks,
        settings_record.ongoing_nomination_area_id
      FROM nominations n;

      -- Delete archived nominations
      DELETE FROM nominations;

      RAISE NOTICE 'Cycle completed and archived: %', completed_cycle_id;
    END IF;

    -- Clear ongoing cycle
    UPDATE settings
    SET
      ongoing_nomination_start_date = NULL,
      ongoing_nomination_end_date = NULL,
      ongoing_nomination_area_id = NULL,
      ongoing_nomination_period = NULL,
      ongoing_cycle_id = NULL
    WHERE id = settings_record.id;
    
    -- Refresh settings record
    SELECT * INTO settings_record
    FROM settings
    LIMIT 1;

    RAISE NOTICE 'Completed cycle archived at %', CURRENT_TIMESTAMP;
  END IF;

  -- Check if we need to start a new cycle
  IF settings_record.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     settings_record.ongoing_nomination_start_date IS NULL THEN
    -- Move next cycle to ongoing
    UPDATE settings
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      -- Set next cycle to start at midnight Paris time the day after ongoing cycle ends
      next_nomination_start_date = date_trunc('day', next_nomination_end_date + interval '1 day')::timestamptz + interval '23 hours',
      next_nomination_area_id = NULL,
      next_nomination_period = 'monthly',
      next_nomination_end_date = NULL
    WHERE id = settings_record.id;

    RAISE NOTICE 'Started new nomination cycle at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Exécuter la fonction pour vérifier si elle fonctionne correctement
SELECT check_and_update_nomination_cycles();

-- Vérifier l'état final
SELECT 
  'État final:' as section,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  ongoing_nomination_period,
  ongoing_nomination_area_id,
  ongoing_cycle_id,
  (SELECT COUNT(*) FROM nominations) as remaining_nominations,
  (SELECT COUNT(*) FROM nomination_history) as archived_nominations
FROM settings;