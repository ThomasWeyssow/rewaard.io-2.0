-- Add cycle_id to nominations table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'nominations' 
    AND column_name = 'cycle_id'
  ) THEN
    ALTER TABLE nominations
    ADD COLUMN cycle_id uuid REFERENCES nomination_cycles(id);
  END IF;
END $$;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_nominations_cycle_id 
ON nominations(cycle_id);

-- Update existing nominations to link with ongoing cycle if dates match
UPDATE nominations n
SET cycle_id = s.ongoing_cycle_id
FROM settings s
WHERE n.cycle_id IS NULL
AND n.nomination_cycle_start = s.ongoing_nomination_start_date
AND n.nomination_cycle_end = s.ongoing_nomination_end_date;

-- Move old nominations to history
WITH old_nominations AS (
  SELECT n.*
  FROM nominations n
  LEFT JOIN settings s ON n.cycle_id = s.ongoing_cycle_id
  WHERE s.ongoing_cycle_id IS NULL
    OR n.cycle_id IS NULL
)
INSERT INTO nomination_history (
  cycle_id,
  cycle_start_date,
  cycle_end_date,
  voter_id,
  nominee_id,
  selected_areas,
  justification,
  remarks,
  nomination_area_id
)
SELECT 
  cycle_id,
  nomination_cycle_start,
  nomination_cycle_end,
  voter_id,
  nominee_id,
  selected_areas,
  justification,
  remarks,
  NULL -- nomination_area_id will be NULL for old nominations
FROM old_nominations;

-- Delete old nominations that have been moved to history
DELETE FROM nominations n
WHERE n.cycle_id IS NULL
   OR n.cycle_id NOT IN (
     SELECT ongoing_cycle_id 
     FROM settings 
     WHERE ongoing_cycle_id IS NOT NULL
   );

-- Create or replace function to set cycle_id on new nominations
CREATE OR REPLACE FUNCTION set_nomination_cycle_id()
RETURNS TRIGGER AS $$
BEGIN
  -- Get ongoing cycle ID from settings
  SELECT ongoing_cycle_id INTO NEW.cycle_id
  FROM settings
  LIMIT 1;
  
  IF NEW.cycle_id IS NULL THEN
    RAISE EXCEPTION 'No ongoing nomination cycle found';
  END IF;
  
  -- Set cycle dates from the cycle
  SELECT 
    start_date,
    end_date 
  INTO 
    NEW.nomination_cycle_start,
    NEW.nomination_cycle_end
  FROM nomination_cycles
  WHERE id = NEW.cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new nominations
DROP TRIGGER IF EXISTS set_nomination_cycle_id_trigger ON nominations;
CREATE TRIGGER set_nomination_cycle_id_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION set_nomination_cycle_id();

-- Add policy to only allow selecting nominations from ongoing cycle
DROP POLICY IF EXISTS "Users can read all nominations" ON nominations;
CREATE POLICY "Users can read ongoing nominations"
  ON nominations FOR SELECT
  TO authenticated
  USING (
    cycle_id IN (
      SELECT ongoing_cycle_id 
      FROM settings 
      WHERE ongoing_cycle_id IS NOT NULL
    )
  );