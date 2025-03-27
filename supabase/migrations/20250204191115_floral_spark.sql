-- Amélioration de la fonction check_and_update_nomination_cycles
CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void AS $$
DECLARE
  settings_record RECORD;
  next_cycle_id uuid;
  ongoing_cycle_id uuid;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
    -- Get ongoing cycle ID
    SELECT id INTO ongoing_cycle_id
    FROM nomination_cycles
    WHERE status = 'ongoing'
    LIMIT 1;

    IF ongoing_cycle_id IS NOT NULL THEN
      -- Move current nominations to history
      WITH nominations_to_archive AS (
        SELECT 
          n.*,
          settings_record.ongoing_nomination_area_id as area_id
        FROM nominations n
        WHERE 
          nomination_cycle_start = settings_record.ongoing_nomination_start_date AND
          nomination_cycle_end = settings_record.ongoing_nomination_end_date
      )
      INSERT INTO nomination_history (
        cycle_id,
        cycle_start_date,
        cycle_end_date,
        voter_id,
        nominee_id,
        selected_areas,
        justification,
        remarks,
        nomination_area_id
      )
      SELECT 
        ongoing_cycle_id,
        settings_record.ongoing_nomination_start_date,
        settings_record.ongoing_nomination_end_date,
        voter_id,
        nominee_id,
        selected_areas,
        justification,
        remarks,
        area_id
      FROM nominations_to_archive;

      -- Update cycle status to completed
      UPDATE nomination_cycles
      SET 
        status = 'completed',
        updated_at = now()
      WHERE id = ongoing_cycle_id;

      -- Delete archived nominations
      DELETE FROM nominations
      WHERE 
        nomination_cycle_start = settings_record.ongoing_nomination_start_date AND
        nomination_cycle_end = settings_record.ongoing_nomination_end_date;
    END IF;

    -- Clear ongoing cycle in settings
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

    RAISE NOTICE 'Archived nominations for cycle ending at %', settings_record.ongoing_nomination_end_date;
  END IF;

  -- Check if we need to start a new cycle
  IF settings_record.next_nomination_start_date <= CURRENT_TIMESTAMP AND 
     settings_record.ongoing_nomination_start_date IS NULL THEN
    
    -- Get or create next cycle
    SELECT id INTO next_cycle_id
    FROM nomination_cycles
    WHERE status = 'next'
    LIMIT 1;

    IF next_cycle_id IS NULL THEN
      -- Create new next cycle if none exists
      INSERT INTO nomination_cycles (
        start_date,
        end_date,
        period,
        nomination_area_id,
        status
      ) VALUES (
        settings_record.next_nomination_start_date,
        settings_record.next_nomination_end_date,
        settings_record.next_nomination_period,
        settings_record.next_nomination_area_id,
        'next'
      )
      RETURNING id INTO next_cycle_id;
    END IF;

    -- Move next cycle to ongoing
    UPDATE nomination_cycles
    SET 
      status = 'ongoing',
      updated_at = now()
    WHERE id = next_cycle_id;

    -- Create new next cycle
    WITH next_cycle_dates AS (
      SELECT
        date_trunc('day', settings_record.next_nomination_end_date + interval '1 day') + interval '23 hours' as start_date,
        CASE 
          WHEN settings_record.next_nomination_period = 'monthly' THEN
            date_trunc('day', settings_record.next_nomination_end_date + interval '1 month') + interval '22 hours' + interval '59 minutes' + interval '59 seconds'
          ELSE
            date_trunc('day', settings_record.next_nomination_end_date + interval '2 months') + interval '22 hours' + interval '59 minutes' + interval '59 seconds'
        END as end_date
    )
    INSERT INTO nomination_cycles (
      start_date,
      end_date,
      period,
      status
    )
    SELECT
      start_date,
      end_date,
      settings_record.next_nomination_period,
      'next'
    FROM next_cycle_dates;

    -- Update settings
    UPDATE settings
    SET
      ongoing_nomination_start_date = next_nomination_start_date,
      ongoing_nomination_end_date = next_nomination_end_date,
      ongoing_nomination_area_id = next_nomination_area_id,
      ongoing_nomination_period = next_nomination_period,
      next_nomination_start_date = date_trunc('day', next_nomination_end_date + interval '1 day') + interval '23 hours',
      next_nomination_area_id = NULL,
      next_nomination_period = NULL,
      next_nomination_end_date = NULL
    WHERE id = settings_record.id;

    RAISE NOTICE 'Started new nomination cycle at %', CURRENT_TIMESTAMP;
  END IF;
END;
$$ LANGUAGE plpgsql;