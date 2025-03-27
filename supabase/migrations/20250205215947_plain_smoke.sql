-- 1. S'assurer que les cycles terminés sont bien marqués comme completed
UPDATE nomination_cycles
SET status = 'completed'
WHERE end_date < CURRENT_TIMESTAMP
  AND status != 'completed'
  AND id NOT IN (
    SELECT ongoing_cycle_id 
    FROM settings 
    WHERE ongoing_cycle_id IS NOT NULL
  );

-- 2. Vérifier et corriger les liens entre nominations et cycles
WITH last_completed_cycle AS (
  SELECT id, start_date, end_date
  FROM nomination_cycles
  WHERE status = 'completed'
  ORDER BY end_date DESC
  LIMIT 1
)
UPDATE nomination_history nh
SET cycle_id = lcc.id
FROM last_completed_cycle lcc
WHERE nh.cycle_id IS NULL
  AND nh.created_at BETWEEN lcc.start_date AND lcc.end_date;

-- 3. Vérifier et corriger les validations
UPDATE nomination_validations nv
SET nominee_id = nh.nominee_id
FROM nomination_history nh
WHERE nv.nominee_id = nh.nominee_id
  AND nh.cycle_id IN (
    SELECT id 
    FROM nomination_cycles 
    WHERE status = 'completed'
  );

-- Vérifier le résultat final
SELECT 
  'État final:' as section,
  (SELECT COUNT(*) FROM nomination_cycles WHERE status = 'completed') as completed_cycles,
  (
    SELECT COUNT(DISTINCT nh.nominee_id) 
    FROM nomination_history nh
    JOIN nomination_cycles nc ON nc.id = nh.cycle_id
    WHERE nc.status = 'completed'
  ) as nominees_with_completed_nominations,
  (
    SELECT COUNT(DISTINCT nv.validator_id)
    FROM nomination_validations nv
    JOIN nomination_history nh ON nh.nominee_id = nv.nominee_id
    JOIN nomination_cycles nc ON nc.id = nh.cycle_id
    WHERE nc.status = 'completed'
  ) as validators_for_completed_nominations;