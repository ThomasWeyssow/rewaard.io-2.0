-- Remove cycle information columns from settings, keeping only references
ALTER TABLE settings
DROP COLUMN IF EXISTS next_nomination_start_date,
DROP COLUMN IF EXISTS next_nomination_end_date,
DROP COLUMN IF EXISTS next_nomination_period,
DROP COLUMN IF EXISTS next_nomination_area_id,
DROP COLUMN IF EXISTS ongoing_nomination_start_date,
DROP COLUMN IF EXISTS ongoing_nomination_end_date,
DROP COLUMN IF EXISTS ongoing_nomination_period,
DROP COLUMN IF EXISTS ongoing_nomination_area_id;

-- Make sure cycle reference columns exist
DO $$ 
BEGIN
  -- Add next_cycle_id if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'settings' 
    AND column_name = 'next_cycle_id'
  ) THEN
    ALTER TABLE settings
    ADD COLUMN next_cycle_id uuid REFERENCES nomination_cycles(id);
  END IF;

  -- Add ongoing_cycle_id if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'settings' 
    AND column_name = 'ongoing_cycle_id'
  ) THEN
    ALTER TABLE settings
    ADD COLUMN ongoing_cycle_id uuid REFERENCES nomination_cycles(id);
  END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_settings_next_cycle 
ON settings(next_cycle_id);

CREATE INDEX IF NOT EXISTS idx_settings_ongoing_cycle 
ON settings(ongoing_cycle_id);

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings updated to only store cycle references:';
  RAISE NOTICE '- Next cycle ID: %', settings_record.next_cycle_id;
  RAISE NOTICE '- Ongoing cycle ID: %', settings_record.ongoing_cycle_id;
END $$;