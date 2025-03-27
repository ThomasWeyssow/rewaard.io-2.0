-- First, verify the nominations table structure
DO $$ 
BEGIN
  -- Add cycle_id column if it doesn't exist
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

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS handle_nomination_insert_trigger ON nominations;
DROP FUNCTION IF EXISTS handle_nomination_insert();

-- Create function to handle nomination insert
CREATE OR REPLACE FUNCTION handle_nomination_insert()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
BEGIN
  -- Get current settings
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;

  -- Log the current state
  RAISE NOTICE 'Handling nomination insert:';
  RAISE NOTICE '- Voter ID: %', NEW.voter_id;
  RAISE NOTICE '- Settings found: %', settings_record IS NOT NULL;
  RAISE NOTICE '- Ongoing cycle ID: %', settings_record.ongoing_cycle_id;
  RAISE NOTICE '- Ongoing start: %', settings_record.ongoing_nomination_start_date;
  RAISE NOTICE '- Ongoing end: %', settings_record.ongoing_nomination_end_date;

  -- Check if there is an active cycle
  IF settings_record.ongoing_nomination_start_date IS NULL THEN
    RAISE EXCEPTION 'No active nomination cycle found';
  END IF;

  IF settings_record.ongoing_nomination_end_date <= CURRENT_TIMESTAMP THEN
    RAISE EXCEPTION 'The current nomination cycle has ended';
  END IF;

  -- Check if user already has a nomination
  IF EXISTS (
    SELECT 1 
    FROM nominations 
    WHERE voter_id = NEW.voter_id
    AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) THEN
    RAISE EXCEPTION 'You can only submit one nomination at a time';
  END IF;

  -- Generate cycle_id if none exists
  IF settings_record.ongoing_cycle_id IS NULL THEN
    WITH updated_settings AS (
      UPDATE settings
      SET ongoing_cycle_id = gen_random_uuid()
      WHERE id = settings_record.id
      RETURNING ongoing_cycle_id
    )
    SELECT ongoing_cycle_id INTO settings_record.ongoing_cycle_id
    FROM updated_settings;
    
    RAISE NOTICE 'Generated new cycle_id: %', settings_record.ongoing_cycle_id;
  END IF;

  -- Set cycle_id from ongoing cycle
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  
  RAISE NOTICE 'Nomination processed successfully with cycle_id: %', NEW.cycle_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new nominations
CREATE TRIGGER handle_nomination_insert_trigger
  BEFORE INSERT ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION handle_nomination_insert();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_nominations_voter_id 
ON nominations(voter_id);

CREATE INDEX IF NOT EXISTS idx_nominations_nominee_id 
ON nominations(nominee_id);

CREATE INDEX IF NOT EXISTS idx_nominations_cycle_id
ON nominations(cycle_id);

-- Verify the current state
SELECT 
  'Current state:' as section,
  (SELECT COUNT(*) FROM nominations) as total_nominations,
  (
    SELECT json_build_object(
      'ongoing_cycle_id', ongoing_cycle_id,
      'start_date', to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS'),
      'end_date', to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS')
    )
    FROM settings
    LIMIT 1
  ) as ongoing_cycle;