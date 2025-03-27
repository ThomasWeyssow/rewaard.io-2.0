-- Drop existing trigger and function
DROP TRIGGER IF EXISTS set_validation_cycle_id_trigger ON nomination_validations;
DROP FUNCTION IF EXISTS set_validation_cycle_id();

-- Create function to set cycle_id on new validations
CREATE OR REPLACE FUNCTION set_validation_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  completed_cycle_id uuid;
BEGIN
  -- Get the last completed cycle ID
  SELECT id INTO completed_cycle_id
  FROM nomination_cycles
  WHERE id = 'ed69fc49-9385-482d-ab42-52e2637d18f5';
  
  IF completed_cycle_id IS NULL THEN
    RAISE EXCEPTION 'No completed nomination cycle found';
  END IF;
  
  -- Set cycle_id from completed cycle
  NEW.cycle_id := completed_cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new validations
CREATE TRIGGER set_validation_cycle_id_trigger
  BEFORE INSERT ON nomination_validations
  FOR EACH ROW
  EXECUTE FUNCTION set_validation_cycle_id();

-- Drop existing policies
DROP POLICY IF EXISTS "validations_select" ON nomination_validations;
DROP POLICY IF EXISTS "validations_insert" ON nomination_validations;
DROP POLICY IF EXISTS "validations_delete" ON nomination_validations;

-- Create new simplified policies for nomination validations
CREATE POLICY "validations_select"
  ON nomination_validations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "validations_insert"
  ON nomination_validations FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow ExCom members to validate nominations
    EXISTS (
      SELECT 1 
      FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'ExCom'
    )
    AND
    -- Ensure validator is the authenticated user
    validator_id = auth.uid()
  );

CREATE POLICY "validations_delete"
  ON nomination_validations FOR DELETE
  TO authenticated
  USING (validator_id = auth.uid());

-- Add unique constraint to prevent multiple validations from same validator
DROP INDEX IF EXISTS idx_nomination_validations_validator_nominee;
ALTER TABLE nomination_validations
DROP CONSTRAINT IF EXISTS nomination_validations_validator_unique;

-- Add new constraint that allows one validation per validator
ALTER TABLE nomination_validations
ADD CONSTRAINT nomination_validations_validator_unique 
UNIQUE (validator_id);

-- Verify the current state
SELECT 
  'Current state:' as section,
  (SELECT COUNT(*) FROM nomination_validations) as active_validations,
  (SELECT COUNT(*) FROM nomination_validations_history) as archived_validations,
  EXISTS (
    SELECT 1 
    FROM nomination_cycles 
    WHERE id = 'ed69fc49-9385-482d-ab42-52e2637d18f5'
  ) as cycle_exists;