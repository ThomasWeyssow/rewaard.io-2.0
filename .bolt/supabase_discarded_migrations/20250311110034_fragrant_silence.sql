/*
  # Add trigger for validation history

  1. Changes
    - Add trigger to handle validation history when a cycle is completed
    - Copy validations to history table when cycle status changes to 'completed'
    - Preserve cycle_id when copying validations

  2. Details
    - Creates a function to handle the validation history
    - Adds a trigger on nomination_cycles table
    - Triggers when status is updated to 'completed'
    - Copies all validations for that cycle to history table
*/

-- Function to handle validation history
CREATE OR REPLACE FUNCTION handle_validation_history()
RETURNS TRIGGER AS $$
BEGIN
  -- If the status is being changed to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
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

-- Create trigger on nomination_cycles table
DROP TRIGGER IF EXISTS handle_validation_history_trigger ON nomination_cycles;
CREATE TRIGGER handle_validation_history_trigger
  AFTER UPDATE ON nomination_cycles
  FOR EACH ROW
  EXECUTE FUNCTION handle_validation_history();