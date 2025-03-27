-- Manually archive completed cycle and its nominations
DO $$
DECLARE
  settings_record RECORD;
  completed_cycle_id uuid;
  nominations_to_archive integer;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Check if ongoing cycle is finished
  IF settings_record.ongoing_nomination_end_date < CURRENT_TIMESTAMP THEN
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

    -- Get count of nominations to archive
    SELECT COUNT(*) INTO nominations_to_archive FROM nominations;

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

      RAISE NOTICE 'Archived % nominations to cycle %', nominations_to_archive, completed_cycle_id;
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

    RAISE NOTICE 'Completed cycle archived at %', CURRENT_TIMESTAMP;
  END IF;
END $$;

-- Verify the archiving
SELECT 
  'État après archivage:' as section,
  (SELECT COUNT(*) FROM nominations) as remaining_nominations,
  (SELECT COUNT(*) FROM nomination_history) as archived_nominations,
  (SELECT COUNT(*) FROM nomination_cycles WHERE status = 'completed') as completed_cycles;