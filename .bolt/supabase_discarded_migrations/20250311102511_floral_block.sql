/*
  # Fix validation cycle ID trigger function

  1. Changes
    - Update set_validation_cycle_id() function to correctly set cycle_id from settings table
    - Use ongoing_cycle_id from settings for current validations
    - Ensure cycle_id is properly set in nomination_validations_history

  2. Security
    - No changes to RLS policies
*/

CREATE OR REPLACE FUNCTION set_validation_cycle_id()
RETURNS TRIGGER AS $$
BEGIN
  -- Get the ongoing cycle ID from settings
  SELECT ongoing_cycle_id INTO NEW.cycle_id
  FROM settings
  LIMIT 1;

  -- If no ongoing cycle found, raise an error
  IF NEW.cycle_id IS NULL THEN
    RAISE EXCEPTION 'No ongoing nomination cycle found';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;