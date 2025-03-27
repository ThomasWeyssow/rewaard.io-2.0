/*
  # Fix validation history cycle ID

  1. Changes
    - Update trigger function to preserve the cycle_id from nomination_validations when moving to history
    - Ensure cycle_id is properly maintained during the transfer process
    - Remove automatic cycle_id assignment to maintain data consistency

  2. Security
    - No changes to RLS policies
*/

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS set_validation_cycle_id_trigger ON nomination_validations_history;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS set_validation_cycle_id();

-- Create new function to handle validation history
CREATE OR REPLACE FUNCTION handle_validation_history()
RETURNS TRIGGER AS $$
BEGIN
  -- Simply use the cycle_id from the source validation
  -- This ensures we maintain the same cycle_id during the transfer
  NEW.cycle_id := OLD.cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create new trigger that preserves cycle_id
CREATE TRIGGER handle_validation_history_trigger
  BEFORE INSERT ON nomination_validations_history
  FOR EACH ROW
  EXECUTE FUNCTION handle_validation_history();