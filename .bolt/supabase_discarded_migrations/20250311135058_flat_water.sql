/*
  # Add validation end date to nomination cycles

  1. Changes
    - Add end_validation_date column to nomination_cycles table
    - Modify handle_validation_history function to set end_validation_date
    - End validation date is set to end_date + 20 days when cycle becomes completed

  2. Details
    - New column is nullable timestamptz
    - Automatically calculated when cycle status changes to 'completed'
    - Used to enforce validation period cutoff
*/

-- Add end_validation_date column
ALTER TABLE nomination_cycles 
ADD COLUMN IF NOT EXISTS end_validation_date timestamptz;

-- Update function to handle validation history and set end date
CREATE OR REPLACE FUNCTION handle_validation_history()
RETURNS TRIGGER AS $$
BEGIN
  -- If the status is being changed to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Set the validation end date to end_date + 20 days
    NEW.end_validation_date := NEW.end_date + INTERVAL '20 days';
    
    -- Insert validations into history
    INSERT INTO nomination_validations_history (
      validator_id,
      nominee_id,
      cycle_id,
      created_at
    )
    SELECT
      validator_id,
      nominee_id,
      cycle_id,
      created_at
    FROM nomination_validations
    WHERE cycle_id = NEW.id;

    -- Delete the original validations
    DELETE FROM nomination_validations
    WHERE cycle_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger to use BEFORE UPDATE instead of AFTER
-- This allows us to modify NEW record
DROP TRIGGER IF EXISTS handle_validation_history_trigger ON nomination_cycles;
CREATE TRIGGER handle_validation_history_trigger
  BEFORE UPDATE ON nomination_cycles
  FOR EACH ROW
  EXECUTE FUNCTION handle_validation_history();