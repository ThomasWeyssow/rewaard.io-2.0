-- Update all cycles that should be completed
WITH cycles_to_complete AS (
  SELECT 
    nc.id,
    nc.end_date,
    nc.status,
    s.ongoing_cycle_id,
    s.next_cycle_id
  FROM nomination_cycles nc
  CROSS JOIN settings s
  WHERE 
    -- Cycle is not the current ongoing or next cycle
    nc.id NOT IN (
      SELECT UNNEST(ARRAY[ongoing_cycle_id, next_cycle_id])
      FROM settings
      WHERE ongoing_cycle_id IS NOT NULL 
         OR next_cycle_id IS NOT NULL
    )
    -- And cycle has ended
    AND nc.end_date < CURRENT_TIMESTAMP
    -- And cycle is not already completed
    AND nc.status != 'completed'
)
UPDATE nomination_cycles nc
SET 
  status = 'completed',
  updated_at = CURRENT_TIMESTAMP
FROM cycles_to_complete ctc
WHERE nc.id = ctc.id;

-- Verify the update
SELECT 
  'Cycles state after update:' as info,
  status,
  COUNT(*) as count,
  MIN(end_date) as earliest_end_date,
  MAX(end_date) as latest_end_date
FROM nomination_cycles
GROUP BY status
ORDER BY status;

-- Double check no cycles are incorrectly marked
SELECT
  'Verification of cycle states:' as info,
  nc.id,
  nc.status,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
  CASE
    WHEN s.ongoing_cycle_id = nc.id THEN 'ongoing'
    WHEN s.next_cycle_id = nc.id THEN 'next'
    WHEN nc.end_date < CURRENT_TIMESTAMP THEN 'should be completed'
    ELSE 'status ok'
  END as status_check
FROM nomination_cycles nc
CROSS JOIN settings s
WHERE nc.status != 'completed'
  AND nc.end_date < CURRENT_TIMESTAMP
  AND nc.id NOT IN (
    SELECT UNNEST(ARRAY[ongoing_cycle_id, next_cycle_id])
    FROM settings
    WHERE ongoing_cycle_id IS NOT NULL 
       OR next_cycle_id IS NOT NULL
  );