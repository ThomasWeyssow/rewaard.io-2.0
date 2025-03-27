/*
  # Update check_and_update_nomination_cycles to handle validation end date

  1. Changes
    - Add end_validation_date calculation when a cycle is completed
    - Set end_validation_date to 20 days after cycle end date
    - Update check_and_update_nomination_cycles function to include this calculation

  2. Security
    - No changes to RLS policies needed
*/

CREATE OR REPLACE FUNCTION check_and_update_nomination_cycles()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_settings record;
  v_ongoing_cycle record;
  v_next_cycle record;
  v_end_validation_date timestamptz;
BEGIN
  -- Get current settings
  SELECT * INTO v_settings FROM settings LIMIT 1;
  
  -- Get ongoing cycle if exists
  IF v_settings.ongoing_cycle_id IS NOT NULL THEN
    SELECT * INTO v_ongoing_cycle 
    FROM nomination_cycles 
    WHERE id = v_settings.ongoing_cycle_id;
  END IF;

  -- Get next cycle if exists
  IF v_settings.next_cycle_id IS NOT NULL THEN
    SELECT * INTO v_next_cycle 
    FROM nomination_cycles 
    WHERE id = v_settings.next_cycle_id;
  END IF;

  -- Check if ongoing cycle should be completed
  IF v_ongoing_cycle.id IS NOT NULL AND v_ongoing_cycle.end_date <= CURRENT_TIMESTAMP THEN
    -- Calculate end_validation_date (20 days after cycle end)
    v_end_validation_date := v_ongoing_cycle.end_date + interval '20 days';
    
    -- Update cycle status to completed and set end_validation_date
    UPDATE nomination_cycles 
    SET 
      status = 'completed',
      end_validation_date = v_end_validation_date
    WHERE id = v_ongoing_cycle.id;

    -- Move nominations to history
    INSERT INTO nomination_history (
      voter_id,
      nominee_id,
      selected_areas,
      justification,
      remarks,
      nomination_area_id,
      cycle_id,
      nomination_cycle_start,
      nomination_cycle_end,
      created_at
    )
    SELECT 
      voter_id,
      nominee_id,
      selected_areas,
      justification,
      remarks,
      n.nomination_area_id,
      cycle_id,
      v_ongoing_cycle.start_date,
      v_ongoing_cycle.end_date,
      n.created_at
    FROM nominations n
    WHERE cycle_id = v_ongoing_cycle.id;

    -- Clean up current nominations
    DELETE FROM nominations WHERE cycle_id = v_ongoing_cycle.id;

    -- Clear ongoing cycle from settings
    UPDATE settings SET
      ongoing_cycle_id = NULL,
      ongoing_nomination_area_id = NULL,
      ongoing_nomination_start_date = NULL,
      ongoing_nomination_end_date = NULL,
      ongoing_nomination_period = NULL;
  END IF;

  -- Check if next cycle should become ongoing
  IF v_next_cycle.id IS NOT NULL AND v_next_cycle.start_date <= CURRENT_TIMESTAMP THEN
    -- Update cycle status
    UPDATE nomination_cycles SET status = 'ongoing' WHERE id = v_next_cycle.id;
    
    -- Update settings
    UPDATE settings SET
      ongoing_cycle_id = v_next_cycle.id,
      ongoing_nomination_area_id = v_next_cycle.nomination_area_id,
      ongoing_nomination_start_date = v_next_cycle.start_date,
      ongoing_nomination_end_date = v_next_cycle.end_date,
      ongoing_nomination_period = v_next_cycle.period,
      next_cycle_id = NULL,
      next_nomination_area_id = NULL,
      next_nomination_start_date = NULL,
      next_nomination_end_date = NULL,
      next_nomination_period = NULL;
  END IF;
END;
$$;