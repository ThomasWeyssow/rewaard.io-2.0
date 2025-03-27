-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop policies if they exist
  DROP POLICY IF EXISTS "Users can read all validations" ON nomination_validations;
  DROP POLICY IF EXISTS "Users can create validations" ON nomination_validations;
  DROP POLICY IF EXISTS "Users can delete their own validations" ON nomination_validations;
  
  -- Drop trigger if it exists
  DROP TRIGGER IF EXISTS update_nomination_validations_updated_at ON nomination_validations;
  
  -- Drop indexes if they exist
  DROP INDEX IF EXISTS idx_nomination_validations_cycle;
  DROP INDEX IF EXISTS idx_nomination_validations_unique_validator_cycle;
END $$;

-- Create or update the table
CREATE TABLE IF NOT EXISTS nomination_validations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  validator_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  nominee_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  cycle_start_date date NOT NULL,
  cycle_end_date date NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE nomination_validations ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read all validations"
  ON nomination_validations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create validations"
  ON nomination_validations FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = validator_id);

CREATE POLICY "Users can delete their own validations"
  ON nomination_validations FOR DELETE
  TO authenticated
  USING (auth.uid() = validator_id);

-- Add trigger for updating timestamps
CREATE TRIGGER update_nomination_validations_updated_at
  BEFORE UPDATE ON nomination_validations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_nomination_validations_cycle 
ON nomination_validations(cycle_start_date, cycle_end_date);

-- Add unique constraint to prevent multiple validations from same user per cycle
CREATE UNIQUE INDEX IF NOT EXISTS idx_nomination_validations_unique_validator_cycle
ON nomination_validations(validator_id, cycle_start_date, cycle_end_date);