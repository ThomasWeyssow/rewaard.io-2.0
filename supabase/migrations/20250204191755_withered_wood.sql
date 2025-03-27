-- Add cycle_id to nominations if not exists
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

-- Update existing nominations with cycle_id
UPDATE nominations n
SET cycle_id = nc.id
FROM nomination_cycles nc
WHERE n.cycle_id IS NULL
AND n.nomination_cycle_start = nc.start_date
AND n.nomination_cycle_end = nc.end_date
AND nc.status = 'ongoing';

-- Create trigger function
CREATE OR REPLACE FUNCTION set_nomination_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  cycle_id uuid;
BEGIN
  -- Get ongoing cycle ID
  SELECT id INTO cycle_id
  FROM nomination_cycles
  WHERE status = 'ongoing'
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
DROP TRIGGER IF EXISTS set_nomination_cycle_id_trigger ON nominations;
CREATE TRIGGER set_nomination_cycle_id_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION set_nomination_cycle_id();