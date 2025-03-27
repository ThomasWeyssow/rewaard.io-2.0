-- Add cycle dates columns to nominations if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'nominations' 
    AND column_name = 'nomination_cycle_start'
  ) THEN
    ALTER TABLE nominations
    ADD COLUMN nomination_cycle_start timestamptz;
  END IF;

  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'nominations' 
    AND column_name = 'nomination_cycle_end'
  ) THEN
    ALTER TABLE nominations
    ADD COLUMN nomination_cycle_end timestamptz;
  END IF;
END $$;

-- Add cycle dates columns to nomination_history if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'nomination_history' 
    AND column_name = 'nomination_cycle_start'
  ) THEN
    ALTER TABLE nomination_history
    ADD COLUMN nomination_cycle_start timestamptz;
  END IF;

  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'nomination_history' 
    AND column_name = 'nomination_cycle_end'
  ) THEN
    ALTER TABLE nomination_history
    ADD COLUMN nomination_cycle_end timestamptz;
  END IF;
END $$;

-- Update nominations with dates from their cycles
UPDATE nominations n
SET 
  nomination_cycle_start = nc.start_date,
  nomination_cycle_end = nc.end_date
FROM nomination_cycles nc
WHERE n.cycle_id = nc.id;

-- Update nomination_history with dates from their cycles
UPDATE nomination_history nh
SET 
  nomination_cycle_start = nc.start_date,
  nomination_cycle_end = nc.end_date
FROM nomination_cycles nc
WHERE nh.cycle_id = nc.id;

-- Update set_nomination_cycle_id function to handle both cycle_id and dates
CREATE OR REPLACE FUNCTION set_nomination_cycle_id()
RETURNS TRIGGER AS $$
DECLARE
  settings_record RECORD;
  cycle_record RECORD;
BEGIN
  -- Get current settings with ongoing cycle
  SELECT * INTO settings_record
  FROM settings
  LIMIT 1;
  
  IF settings_record.ongoing_cycle_id IS NULL THEN
    RAISE EXCEPTION 'No ongoing nomination cycle found';
  END IF;
  
  -- Get cycle dates
  SELECT * INTO cycle_record
  FROM nomination_cycles
  WHERE id = settings_record.ongoing_cycle_id;
  
  -- Set both cycle_id and dates
  NEW.cycle_id := settings_record.ongoing_cycle_id;
  NEW.nomination_cycle_start := cycle_record.start_date;
  NEW.nomination_cycle_end := cycle_record.end_date;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;