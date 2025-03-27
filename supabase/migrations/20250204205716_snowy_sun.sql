-- Drop existing cycle reference columns if they exist
ALTER TABLE settings
DROP COLUMN IF EXISTS next_cycle_id,
DROP COLUMN IF EXISTS ongoing_cycle_id;

-- Add all required columns
ALTER TABLE settings
ADD COLUMN next_nomination_start_date timestamptz,
ADD COLUMN next_nomination_end_date timestamptz,
ADD COLUMN next_nomination_period text CHECK (next_nomination_period IN ('monthly', 'bi-monthly')),
ADD COLUMN next_nomination_area_id uuid REFERENCES nomination_areas(id),
ADD COLUMN ongoing_nomination_start_date timestamptz,
ADD COLUMN ongoing_nomination_end_date timestamptz,
ADD COLUMN ongoing_nomination_period text CHECK (ongoing_nomination_period IN ('monthly', 'bi-monthly')),
ADD COLUMN ongoing_nomination_area_id uuid REFERENCES nomination_areas(id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_settings_next_nomination_area 
ON settings(next_nomination_area_id);

CREATE INDEX IF NOT EXISTS idx_settings_ongoing_nomination_area 
ON settings(ongoing_nomination_area_id);

CREATE INDEX IF NOT EXISTS idx_settings_next_nomination_dates 
ON settings(next_nomination_start_date, next_nomination_end_date);

CREATE INDEX IF NOT EXISTS idx_settings_ongoing_nomination_dates 
ON settings(ongoing_nomination_start_date, ongoing_nomination_end_date);

-- Initialize settings with default values if none exist
INSERT INTO settings (
  next_nomination_start_date,
  next_nomination_period
)
SELECT 
  date_trunc('day', CURRENT_TIMESTAMP + interval '1 day') + interval '23 hours',
  'monthly'
WHERE NOT EXISTS (SELECT 1 FROM settings);

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings table updated with all required columns:';
  RAISE NOTICE '- Next nomination start: %', settings_record.next_nomination_start_date;
  RAISE NOTICE '- Next nomination period: %', settings_record.next_nomination_period;
END $$;