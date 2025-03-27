-- Add missing columns to settings if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'settings' 
    AND column_name = 'next_nomination_area_id'
  ) THEN
    ALTER TABLE settings
    ADD COLUMN next_nomination_area_id uuid REFERENCES nomination_areas(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'settings' 
    AND column_name = 'next_nomination_period'
  ) THEN
    ALTER TABLE settings
    ADD COLUMN next_nomination_period text CHECK (next_nomination_period IN ('monthly', 'bi-monthly'));
  END IF;
END $$;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_settings_next_nomination_area 
ON settings(next_nomination_area_id);

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings updated:';
  RAISE NOTICE '- Next nomination area ID: %', settings_record.next_nomination_area_id;
  RAISE NOTICE '- Next nomination period: %', settings_record.next_nomination_period;
END $$;