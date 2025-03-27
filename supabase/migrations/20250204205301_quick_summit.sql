-- Add missing columns to settings if they don't exist
DO $$ 
BEGIN
  -- Add next_nomination_area_id if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'settings' 
    AND column_name = 'next_nomination_area_id'
  ) THEN
    ALTER TABLE settings
    ADD COLUMN next_nomination_area_id uuid REFERENCES nomination_areas(id);
  END IF;

  -- Add next_nomination_period if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'settings' 
    AND column_name = 'next_nomination_period'
  ) THEN
    ALTER TABLE settings
    ADD COLUMN next_nomination_period text CHECK (next_nomination_period IN ('monthly', 'bi-monthly'));
  END IF;

  -- Add next_nomination_start_date if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'settings' 
    AND column_name = 'next_nomination_start_date'
  ) THEN
    ALTER TABLE settings
    ADD COLUMN next_nomination_start_date timestamptz;
  END IF;

  -- Add next_nomination_end_date if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'settings' 
    AND column_name = 'next_nomination_end_date'
  ) THEN
    ALTER TABLE settings
    ADD COLUMN next_nomination_end_date timestamptz;
  END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_settings_next_nomination_area 
ON settings(next_nomination_area_id);

CREATE INDEX IF NOT EXISTS idx_settings_next_nomination_dates 
ON settings(next_nomination_start_date, next_nomination_end_date);

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings updated:';
  RAISE NOTICE '- Next nomination area ID: %', settings_record.next_nomination_area_id;
  RAISE NOTICE '- Next nomination period: %', settings_record.next_nomination_period;
  RAISE NOTICE '- Next nomination start date: %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination end date: %', settings_record.next_nomination_end_date;
END $$;