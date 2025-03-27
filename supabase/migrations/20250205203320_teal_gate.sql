-- Drop existing foreign key constraint
ALTER TABLE nomination_validations
DROP CONSTRAINT IF EXISTS nomination_validations_cycle_id_fkey;

-- Drop cycle_id column since we don't need it anymore
ALTER TABLE nomination_validations
DROP COLUMN IF EXISTS cycle_id;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read all validations" ON nomination_validations;
DROP POLICY IF EXISTS "Users can create validations" ON nomination_validations;
DROP POLICY IF EXISTS "Users can delete their own validations" ON nomination_validations;

-- Create simplified policies
CREATE POLICY "validations_select"
  ON nomination_validations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "validations_insert"
  ON nomination_validations FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "validations_delete"
  ON nomination_validations FOR DELETE
  TO authenticated
  USING (validator_id = auth.uid());

-- Add unique constraint to prevent multiple validations from same validator
CREATE UNIQUE INDEX IF NOT EXISTS idx_nomination_validations_validator_nominee
ON nomination_validations(validator_id, nominee_id);

-- Log the changes
DO $$
BEGIN
  RAISE NOTICE 'Nomination validations table updated:';
  RAISE NOTICE '- Removed cycle_id dependency';
  RAISE NOTICE '- Added unique constraint on validator_id + nominee_id';
  RAISE NOTICE '- Simplified RLS policies';
END $$;