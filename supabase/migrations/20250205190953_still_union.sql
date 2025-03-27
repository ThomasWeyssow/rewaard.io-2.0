-- Create cycle entry for ongoing cycle
WITH ongoing_cycle AS (
  INSERT INTO nomination_cycles (
    start_date,
    end_date,
    period,
    nomination_area_id,
    status
  )
  SELECT
    ongoing_nomination_start_date,
    ongoing_nomination_end_date,
    ongoing_nomination_period,
    ongoing_nomination_area_id,
    'ongoing'
  FROM settings
  WHERE ongoing_nomination_start_date IS NOT NULL
  RETURNING id
)
-- Link the cycle to settings
UPDATE settings
SET ongoing_cycle_id = (SELECT id FROM ongoing_cycle)
WHERE ongoing_nomination_start_date IS NOT NULL;

-- Verify the update
SELECT 
  'Settings state:' as info,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  ongoing_nomination_period,
  ongoing_nomination_area_id,
  ongoing_cycle_id
FROM settings;