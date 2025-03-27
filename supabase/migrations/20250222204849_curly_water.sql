-- Drop existing check constraint
ALTER TABLE settings
DROP CONSTRAINT IF EXISTS settings_next_nomination_period_check;

-- Add updated check constraint
ALTER TABLE settings
ADD CONSTRAINT settings_next_nomination_period_check 
CHECK (next_nomination_period IN ('monthly', 'bi-monthly', NULL));

-- Add similar constraint for ongoing period
ALTER TABLE settings
DROP CONSTRAINT IF EXISTS settings_ongoing_nomination_period_check;

ALTER TABLE settings
ADD CONSTRAINT settings_ongoing_nomination_period_check 
CHECK (ongoing_nomination_period IN ('monthly', 'bi-monthly', NULL));

-- Update any existing NULL values to 'monthly'
UPDATE settings
SET 
  next_nomination_period = 'monthly'
WHERE next_nomination_period IS NULL;

UPDATE settings
SET 
  ongoing_nomination_period = 'monthly'
WHERE ongoing_nomination_period IS NULL;

-- Log the changes
DO $$
DECLARE
  settings_record RECORD;
BEGIN
  SELECT * INTO settings_record FROM settings LIMIT 1;
  
  RAISE NOTICE 'Settings updated:';
  RAISE NOTICE '- Next nomination period: %', settings_record.next_nomination_period;
  RAISE NOTICE '- Ongoing nomination period: %', settings_record.ongoing_nomination_period;
END $$;