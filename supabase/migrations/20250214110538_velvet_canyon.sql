-- Add cycle_id column to nomination_validations
ALTER TABLE nomination_validations
ADD COLUMN cycle_id uuid REFERENCES nomination_cycles(id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_nomination_validations_cycle_id 
ON nomination_validations(cycle_id);

-- Update existing validations to link with their cycle
UPDATE nomination_validations nv
SET cycle_id = nc.id
FROM nomination_cycles nc
WHERE nc.status = 'completed'
  AND nc.start_date <= nv.created_at
  AND nc.end_date >= nv.created_at;

-- Update set_validation_cycle_id function to handle cycle_id
CREATE OR REPLACE FUNCTION set_validation_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;
  
  IF settings_record.ongoing_cycle_id IS NULL THEN
    RAISE EXCEPTION 'No ongoing nomination cycle found';
  END IF;
  
  -- Set cycle id from settings
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing policies
DROP POLICY IF EXISTS "validations_select_policy" ON nomination_validations;
DROP POLICY IF EXISTS "validations_insert_policy" ON nomination_validations;
DROP POLICY IF EXISTS "validations_delete_policy" ON nomination_validations;

-- Create new policies that handle cycle_id
CREATE POLICY "validations_select_policy"
  ON nomination_validations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "validations_insert_policy"
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
    -- Only during an active cycle
    EXISTS (
      SELECT 1 
      FROM settings s 
      WHERE s.ongoing_cycle_id IS NOT NULL
    )
  );

CREATE POLICY "validations_delete_policy"
  ON nomination_validations FOR DELETE
  TO authenticated
  USING (
    -- Allow users to remove their own validations
    validator_id = auth.uid()
    AND
    -- Only during an active cycle
    EXISTS (
      SELECT 1 
      FROM settings s 
      WHERE s.ongoing_cycle_id IS NOT NULL
    )
  );

-- Log the changes
DO $$
BEGIN
  RAISE NOTICE 'Added cycle_id to nomination_validations and updated policies';
END $$;