/*
  # Add end_validation_date calculation to nomination cycles

  1. Changes
    - Add end_validation_date calculation when a cycle is completed
    - Set end_validation_date to 20 days after cycle end date
    - Update handle_nomination_cycles function to include this calculation

  2. Security
    - No changes to RLS policies needed
*/

-- Update the handle_nomination_cycles function to include end_validation_date calculation
CREATE OR REPLACE FUNCTION handle_nomination_cycles()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_cycle_id uuid;
  v_end_date timestamptz;
  v_end_validation_date timestamptz;
BEGIN
  -- If there's an ongoing cycle being completed
  IF OLD.ongoing_cycle_id IS NOT NULL AND NEW.ongoing_cycle_id IS NULL THEN
    -- Calculate end_validation_date (20 days after cycle end)
    v_end_validation_date := OLD.ongoing_nomination_end_date + interval '20 days';
    
    -- Update the cycle status to completed and set end_validation_date
    UPDATE nomination_cycles
    SET 
      status = 'completed',
      end_validation_date = v_end_validation_date
    WHERE id = OLD.ongoing_cycle_id;

    -- Move validations to history
    INSERT INTO nomination_validations_history (
      cycle_id,
      validator_id,
      nominee_id,
      created_at
    )
    SELECT 
      cycle_id,
      validator_id,
      nominee_id,
      created_at
    FROM nomination_validations
    WHERE cycle_id = OLD.ongoing_cycle_id;

    -- Clean up current validations
    DELETE FROM nomination_validations
    WHERE cycle_id = OLD.ongoing_cycle_id;
  END IF;

  -- If there's a next cycle ready to start
  IF NEW.next_nomination_start_date IS NOT NULL 
    AND NEW.next_nomination_area_id IS NOT NULL 
    AND NEW.next_nomination_period IS NOT NULL THEN
    
    -- Calculate the end date based on the period
    v_end_date := NEW.next_nomination_start_date + 
      CASE 
        WHEN NEW.next_nomination_period = 'monthly' THEN interval '1 month'
        WHEN NEW.next_nomination_period = 'bi-monthly' THEN interval '2 months'
      END - interval '1 day';

    -- Create the new cycle
    INSERT INTO nomination_cycles (
      start_date,
      end_date,
      period,
      nomination_area_id,
      status
    ) VALUES (
      NEW.next_nomination_start_date,
      v_end_date,
      NEW.next_nomination_period,
      NEW.next_nomination_area_id,
      'next'
    ) RETURNING id INTO v_cycle_id;

    -- Update settings with the new cycle
    NEW.next_cycle_id := v_cycle_id;
    NEW.next_nomination_end_date := v_end_date;
  END IF;

  RETURN NEW;
END;
$$;