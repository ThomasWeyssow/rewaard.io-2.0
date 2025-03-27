-- Initialize cycles for existing settings
WITH settings_data AS (
  SELECT 
    next_nomination_start_date,
    next_nomination_end_date,
    next_nomination_period,
    next_nomination_area_id,
    ongoing_nomination_start_date,
    ongoing_nomination_end_date,
    ongoing_nomination_period,
    ongoing_nomination_area_id
  FROM settings
  LIMIT 1
),
next_cycle AS (
  INSERT INTO nomination_cycles (
    start_date,
    end_date,
    period,
    nomination_area_id,
    status
  )
  SELECT 
    next_nomination_start_date,
    next_nomination_end_date,
    next_nomination_period,
    next_nomination_area_id,
    'next'
  FROM settings_data
  WHERE next_nomination_start_date IS NOT NULL
  RETURNING id
),
ongoing_cycle AS (
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
  FROM settings_data
  WHERE ongoing_nomination_start_date IS NOT NULL
  RETURNING id
)
UPDATE settings
SET 
  next_cycle_id = (SELECT id FROM next_cycle LIMIT 1),
  ongoing_cycle_id = (SELECT id FROM ongoing_cycle LIMIT 1)
WHERE id IS NOT NULL;

-- Verify the current state
SELECT 
  'Current state:' as info,
  to_char(next_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_start,
  to_char(next_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_end,
  next_nomination_period,
  next_nomination_area_id,
  next_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  ongoing_nomination_period,
  ongoing_nomination_area_id,
  ongoing_cycle_id
FROM settings;