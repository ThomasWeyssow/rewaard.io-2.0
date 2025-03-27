-- First, update any NULL or invalid periods to 'monthly'
UPDATE nomination_cycles
SET period = 'monthly'
WHERE period IS NULL OR period NOT IN ('monthly', 'bi-monthly');

UPDATE settings
SET 
  next_nomination_period = 'monthly'
WHERE next_nomination_period IS NULL OR next_nomination_period NOT IN ('monthly', 'bi-monthly');

UPDATE settings
SET 
  ongoing_nomination_period = 'monthly'
WHERE ongoing_nomination_period IS NULL OR ongoing_nomination_period NOT IN ('monthly', 'bi-monthly');

-- Drop existing period check constraints
ALTER TABLE nomination_cycles
DROP CONSTRAINT IF EXISTS nomination_cycles_period_check;

ALTER TABLE settings
DROP CONSTRAINT IF EXISTS settings_next_nomination_period_check,
DROP CONSTRAINT IF EXISTS settings_ongoing_nomination_period_check;

-- Add updated period check constraints
ALTER TABLE nomination_cycles
ADD CONSTRAINT nomination_cycles_period_check 
CHECK (period IN ('monthly', 'bi-monthly'));

ALTER TABLE settings
ADD CONSTRAINT settings_next_nomination_period_check 
CHECK (next_nomination_period IN ('monthly', 'bi-monthly', NULL)),
ADD CONSTRAINT settings_ongoing_nomination_period_check 
CHECK (ongoing_nomination_period IN ('monthly', 'bi-monthly', NULL));

-- Verify the current state
SELECT 
  'Current state:' as section,
  'Nomination cycles:' as subsection,
  status,
  period,
  to_char(start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
  to_char(end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date
FROM nomination_cycles
ORDER BY 
  CASE status
    WHEN 'next' THEN 1
    WHEN 'ongoing' THEN 2
    WHEN 'completed' THEN 3
  END;

SELECT 
  'Settings:' as subsection,
  next_nomination_period,
  ongoing_nomination_period
FROM settings;