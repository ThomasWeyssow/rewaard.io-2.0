-- Créer un cycle complété par défaut si aucun n'existe
WITH default_cycle AS (
  INSERT INTO nomination_cycles (
    start_date,
    end_date,
    period,
    status
  )
  SELECT
    CURRENT_TIMESTAMP - interval '1 month',
    CURRENT_TIMESTAMP - interval '1 day',
    'monthly',
    'completed'
  WHERE NOT EXISTS (
    SELECT 1 
    FROM nomination_cycles 
    WHERE status = 'completed'
  )
  RETURNING id
),
-- Créer une nomination historique par défaut si aucune n'existe
default_nomination AS (
  INSERT INTO nomination_history (
    cycle_id,
    voter_id,
    nominee_id,
    selected_areas,
    justification,
    remarks
  )
  SELECT 
    dc.id,
    (SELECT id FROM profiles WHERE email = 'nicolas@gmail.com'),
    (SELECT id FROM profiles WHERE email = 'emma.laurent@company.com'),
    ARRAY['Vision stratégique', 'Innovation'],
    'Excellente contribution sur le projet Hero Program',
    'A démontré un leadership exceptionnel'
  FROM default_cycle dc
  WHERE NOT EXISTS (
    SELECT 1 
    FROM nomination_history
  )
)
SELECT 'Données initiales créées' as result;

-- Mettre à jour la fonction check_and_update_nomination_cycles pour gérer le cas où il n'y a pas de nominations
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  nominations_to_archive integer;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    -- Only archive if there is an ongoing cycle
    IF settings_record.ongoing_nomination_start_date IS NOT NULL AND 
       settings_record.ongoing_nomination_end_date IS NOT NULL AND
       settings_record.ongoing_cycle_id IS NOT NULL THEN
      -- Get count of nominations to archive
      SELECT COUNT(*) INTO nominations_to_archive FROM nominations;

      -- Create completed cycle entry using the existing ongoing_cycle_id
      INSERT INTO nomination_cycles (
        id,
        start_date,
        end_date,
        period,
        nomination_area_id,
        status
      )
      VALUES (
        settings_record.ongoing_cycle_id,
        settings_record.ongoing_nomination_start_date,
        settings_record.ongoing_nomination_end_date,
        settings_record.ongoing_nomination_period,
        settings_record.ongoing_nomination_area_id,
        'completed'
      );

      -- Move nominations to history if any exist
      IF nominations_to_archive > 0 THEN
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
          settings_record.ongoing_cycle_id,
          n.voter_id,
          n.nominee_id,
          n.selected_areas,
          n.justification,
          n.remarks,
          settings_record.ongoing_nomination_area_id
        FROM nominations n;

        -- Delete archived nominations with WHERE clause
        DELETE FROM nominations n
        WHERE EXISTS (
          SELECT 1 
          FROM nomination_history nh 
          WHERE nh.cycle_id = settings_record.ongoing_cycle_id
            AND nh.voter_id = n.voter_id
            AND nh.nominee_id = n.nominee_id
        );

        RAISE NOTICE 'Archived % nominations to cycle %', nominations_to_archive, settings_record.ongoing_cycle_id;
      ELSE
        RAISE NOTICE 'No nominations to archive for cycle %', settings_record.ongoing_cycle_id;
      END IF;
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
    -- Generate new cycle_id
    WITH new_cycle AS (
      SELECT gen_random_uuid() as id
    )
    -- Move next cycle to ongoing with new cycle_id
    UPDATE settings s
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      ongoing_cycle_id = nc.id,
      -- Set next cycle to start at midnight Paris time the day after ongoing cycle ends
      next_nomination_start_date = date_trunc('day', next_nomination_end_date + interval '1 day')::timestamptz + interval '23 hours',
      next_nomination_area_id = NULL,
      next_nomination_period = 'monthly',
      next_nomination_end_date = NULL
    FROM new_cycle nc
    WHERE s.id = settings_record.id;

    RAISE NOTICE 'Started new nomination cycle at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Vérifier l'état final
SELECT 
  'État final:' as section,
  (SELECT COUNT(*) FROM nomination_cycles WHERE status = 'completed') as completed_cycles,
  (SELECT COUNT(*) FROM nomination_history) as archived_nominations,
  (SELECT COUNT(*) FROM nominations) as active_nominations;