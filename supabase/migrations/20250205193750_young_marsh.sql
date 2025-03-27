-- Drop existing trigger and function
DROP TRIGGER IF EXISTS set_nomination_cycle_id_trigger ON nominations;
DROP FUNCTION IF EXISTS set_nomination_cycle_id;

-- Create updated function to set cycle_id on new nominations
CREATE OR REPLACE FUNCTION set_nomination_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
  cycle_id uuid;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;
  
  -- Check if we need to create an ongoing cycle
  IF settings_record.ongoing_cycle_id IS NULL AND 
     settings_record.ongoing_nomination_start_date IS NOT NULL AND
     settings_record.ongoing_nomination_end_date IS NOT NULL THEN
    -- Create new cycle
    INSERT INTO nomination_cycles (
      start_date,
      end_date,
      period,
      nomination_area_id,
      status
    )
    VALUES (
      settings_record.ongoing_nomination_start_date,
      settings_record.ongoing_nomination_end_date,
      settings_record.ongoing_nomination_period,
      settings_record.ongoing_nomination_area_id,
      'ongoing'
    )
    RETURNING id INTO cycle_id;

    -- Update settings with new cycle_id
    UPDATE settings
    SET ongoing_cycle_id = cycle_id
    WHERE id = settings_record.id;
    
    -- Use the new cycle_id
    NEW.cycle_id := cycle_id;
  ELSE
    -- Use existing cycle_id
    NEW.cycle_id := settings_record.ongoing_cycle_id;
  END IF;
  
  IF NEW.cycle_id IS NULL THEN
    RAISE EXCEPTION 'No ongoing nomination cycle available';
  END IF;

  -- Set nomination cycle dates
  NEW.nomination_cycle_start := settings_record.ongoing_nomination_start_date;
  NEW.nomination_cycle_end := settings_record.ongoing_nomination_end_date;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new nominations
CREATE TRIGGER set_nomination_cycle_id_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION set_nomination_cycle_id();

-- Drop existing policies
DROP POLICY IF EXISTS "nominations_select" ON nominations;
DROP POLICY IF EXISTS "nominations_insert" ON nominations;
DROP POLICY IF EXISTS "nominations_delete" ON nominations;

-- Create simplified policies
CREATE POLICY "nominations_select"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "nominations_insert"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM settings 
      WHERE ongoing_nomination_start_date IS NOT NULL
    )
  );

CREATE POLICY "nominations_delete"
  ON nominations FOR DELETE
  TO authenticated
  USING (voter_id = auth.uid());

-- Create ongoing cycle for existing settings if needed
DO $$
DECLARE
  settings_record RECORD;
  cycle_id uuid;
BEGIN
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;
  
  IF settings_record.ongoing_cycle_id IS NULL AND 
     settings_record.ongoing_nomination_start_date IS NOT NULL AND
     settings_record.ongoing_nomination_end_date IS NOT NULL THEN
    -- Create new cycle
    INSERT INTO nomination_cycles (
      start_date,
      end_date,
      period,
      nomination_area_id,
      status
    )
    VALUES (
      settings_record.ongoing_nomination_start_date,
      settings_record.ongoing_nomination_end_date,
      settings_record.ongoing_nomination_period,
      settings_record.ongoing_nomination_area_id,
      'ongoing'
    )
    RETURNING id INTO cycle_id;

    -- Update settings with new cycle_id
    UPDATE settings
    SET ongoing_cycle_id = cycle_id
    WHERE id = settings_record.id;
    
    RAISE NOTICE 'Created new ongoing cycle with ID: %', cycle_id;
  END IF;
END $$;

-- Update existing nominations to link with ongoing cycle if needed
UPDATE nominations n
SET 
  cycle_id = s.ongoing_cycle_id,
  nomination_cycle_start = s.ongoing_nomination_start_date,
  nomination_cycle_end = s.ongoing_nomination_end_date
FROM settings s
WHERE n.cycle_id IS NULL
  AND s.ongoing_cycle_id IS NOT NULL
  AND s.ongoing_nomination_start_date IS NOT NULL
  AND s.ongoing_nomination_end_date IS NOT NULL;

-- Verify the current state
SELECT 
  'Current state:' as info,
  COUNT(*) as total_nominations,
  COUNT(DISTINCT cycle_id) as unique_cycles,
  EXISTS (
    SELECT 1 
    FROM settings 
    WHERE ongoing_cycle_id IS NOT NULL
  ) as has_ongoing_cycle
FROM nominations;

-- Log the current settings state
SELECT 
  'Settings state:' as info,
  ongoing_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end
FROM settings;