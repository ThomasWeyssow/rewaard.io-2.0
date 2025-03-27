-- Add cycle_id to nomination_validations if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'nomination_validations' 
    AND column_name = 'cycle_id'
  ) THEN
    ALTER TABLE nomination_validations
    ADD COLUMN cycle_id uuid REFERENCES nomination_cycles(id);
  END IF;
END $$;

-- Create index for better performance if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_nomination_validations_cycle_id 
ON nomination_validations(cycle_id);

-- Update existing validations with the specified cycle ID
UPDATE nomination_validations
SET cycle_id = '397e7a6b-4996-495d-a900-138c0559161d'
WHERE cycle_id IS NULL
AND EXISTS (
  SELECT 1 
  FROM nomination_cycles 
  WHERE id = '397e7a6b-4996-495d-a900-138c0559161d'
);

-- Make cycle_id required if it isn't already
DO $$
BEGIN
  ALTER TABLE nomination_validations
  ALTER COLUMN cycle_id SET NOT NULL;
EXCEPTION
  WHEN others THEN
    NULL;  -- Ignore error if column is already NOT NULL
END $$;

-- Drop old date columns if they exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'nomination_validations' 
    AND column_name IN ('cycle_start_date', 'cycle_end_date')
  ) THEN
    ALTER TABLE nomination_validations
    DROP COLUMN cycle_start_date,
    DROP COLUMN cycle_end_date;
  END IF;
END $$;

-- Update trigger function to handle cycle_id
CREATE OR REPLACE FUNCTION set_validation_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  cycle_id uuid;
BEGIN
  -- Get ongoing cycle ID from settings
  SELECT ongoing_cycle_id INTO cycle_id
  FROM settings
  LIMIT 1;
  
  IF cycle_id IS NULL THEN
    RAISE EXCEPTION 'No ongoing nomination cycle found';
  END IF;
  
  -- Set the cycle_id
  NEW.cycle_id := cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS set_validation_cycle_id_trigger ON nomination_validations;
CREATE TRIGGER set_validation_cycle_id_trigger
  BEFORE INSERT ON nomination_validations
  FOR EACH ROW
  EXECUTE FUNCTION set_validation_cycle_id();