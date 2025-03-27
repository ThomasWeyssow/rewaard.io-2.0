-- Drop existing period check constraint
ALTER TABLE nomination_cycles
DROP CONSTRAINT IF EXISTS nomination_cycles_period_check;

-- Add updated period check constraint
ALTER TABLE nomination_cycles
ADD CONSTRAINT nomination_cycles_period_check 
CHECK (period IN ('monthly', 'bi-monthly'));

-- Update any NULL periods to 'monthly'
UPDATE nomination_cycles
SET period = 'monthly'
WHERE period IS NULL;

-- Verify the current state
SELECT 
  'Current state:' as section,
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