-- Verify current state of nomination cycles
WITH cycle_info AS (
  SELECT 
    nc.id,
    nc.status,
    nc.period,
    nc.nomination_area_id,
    to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
    to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
    s.next_cycle_id,
    s.ongoing_cycle_id
  FROM nomination_cycles nc
  CROSS JOIN settings s
  ORDER BY 
    CASE nc.status
      WHEN 'next' THEN 1
      WHEN 'ongoing' THEN 2
      WHEN 'completed' THEN 3
    END
)
SELECT 
  'Current nomination cycles state:' as info,
  *
FROM cycle_info;

-- Create a test cycle to verify insertion
WITH new_cycle AS (
  INSERT INTO nomination_cycles (
    start_date,
    end_date,
    period,
    status
  )
  VALUES (
    date_trunc('day', CURRENT_TIMESTAMP + interval '1 day') + interval '23 hours',
    date_trunc('day', CURRENT_TIMESTAMP + interval '1 month') + interval '22 hours' + interval '59 minutes' + interval '59 seconds',
    'monthly',
    'next'
  )
  RETURNING 
    id,
    to_char(start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
    to_char(end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
    period,
    status
)
SELECT 
  'New test cycle created:' as info,
  *
FROM new_cycle;

-- Update settings to reference the new cycle
WITH updated_settings AS (
  UPDATE settings
  SET next_cycle_id = (
    SELECT id 
    FROM nomination_cycles 
    WHERE status = 'next' 
    ORDER BY start_date DESC 
    LIMIT 1
  )
  WHERE next_cycle_id IS NULL
  RETURNING next_cycle_id, ongoing_cycle_id
)
SELECT 
  'Settings updated:' as info,
  *
FROM updated_settings;

-- Verify final state
SELECT 
  'Final state:' as info,
  nc.status,
  to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
  nc.period,
  nc.nomination_area_id,
  CASE 
    WHEN s.next_cycle_id = nc.id THEN 'Next cycle'
    WHEN s.ongoing_cycle_id = nc.id THEN 'Ongoing cycle'
    ELSE NULL
  END as cycle_type
FROM nomination_cycles nc
CROSS JOIN settings s
ORDER BY 
  CASE nc.status
    WHEN 'next' THEN 1
    WHEN 'ongoing' THEN 2
    WHEN 'completed' THEN 3
  END;