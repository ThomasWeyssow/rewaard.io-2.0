-- Drop existing trigger and function
DROP TRIGGER IF EXISTS set_validation_cycle_id_trigger ON nomination_validations;
DROP FUNCTION IF EXISTS set_validation_cycle_id();

-- Create updated function to set cycle_id on new validations
CREATE OR REPLACE FUNCTION set_validation_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  last_completed_cycle_id uuid;
BEGIN
  -- Get the last completed cycle ID
  SELECT id INTO last_completed_cycle_id
  FROM nomination_cycles
  WHERE status = 'completed'
  ORDER BY end_date DESC
  LIMIT 1;
  
  IF last_completed_cycle_id IS NULL THEN
    RAISE EXCEPTION 'No completed nomination cycle found';
  END IF;
  
  -- Set cycle_id from the last completed cycle
  NEW.cycle_id := last_completed_cycle_id;
  
  -- Log for debugging
  RAISE NOTICE 'Setting validation cycle_id to %', last_completed_cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new validations
CREATE TRIGGER set_validation_cycle_id_trigger
  BEFORE INSERT ON nomination_validations
  FOR EACH ROW
  EXECUTE FUNCTION set_validation_cycle_id();

-- Verify the current state
SELECT 
  'Current state:' as section,
  nc.id as cycle_id,
  nc.status,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
  COUNT(nv.id) as validation_count
FROM nomination_cycles nc
LEFT JOIN nomination_validations nv ON nv.cycle_id = nc.id
WHERE nc.status = 'completed'
GROUP BY nc.id, nc.status, nc.end_date
ORDER BY nc.end_date DESC;