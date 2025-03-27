-- Vérifier la nomination spécifique
WITH nomination_check AS (
  SELECT 
    nh.id as nomination_id,
    nh.voter_id,
    nh.nominee_id,
    nh.cycle_id,
    nh.selected_areas,
    nh.justification,
    nh.remarks,
    p_voter.email as voter_email,
    p_nominee.email as nominee_email,
    p_nominee.department as nominee_department,
    nc.status as cycle_status,
    to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_start,
    to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_end,
    COUNT(nv.validator_id) as validation_count
  FROM nomination_history nh
  JOIN profiles p_voter ON p_voter.id = nh.voter_id
  JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
  LEFT JOIN nomination_cycles nc ON nc.id = nh.cycle_id
  LEFT JOIN nomination_validations nv ON nv.nominee_id = nh.nominee_id
  WHERE nh.id = '37b87873-e1cc-4cf0-bce4-2b4bcf01185d'
  GROUP BY 
    nh.id, 
    nh.voter_id,
    nh.nominee_id,
    nh.cycle_id,
    nh.selected_areas,
    nh.justification,
    nh.remarks,
    p_voter.email,
    p_nominee.email,
    p_nominee.department,
    nc.status,
    nc.start_date,
    nc.end_date
)
SELECT 
  'État de la nomination:' as section,
  *
FROM nomination_check;

-- S'assurer que la nomination est liée au dernier cycle complété
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
WHERE nh.id = '37b87873-e1cc-4cf0-bce4-2b4bcf01185d'
  AND (nh.cycle_id IS NULL OR nh.cycle_id NOT IN (
    SELECT id FROM nomination_cycles WHERE status = 'completed'
  ));

-- Vérifier l'état final
SELECT 
  'État final de la nomination:' as section,
  nh.id as nomination_id,
  nh.cycle_id,
  nc.status as cycle_status,
  to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_start,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_end,
  p_nominee.email as nominee_email,
  COUNT(nv.validator_id) as validation_count
FROM nomination_history nh
JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
LEFT JOIN nomination_cycles nc ON nc.id = nh.cycle_id
LEFT JOIN nomination_validations nv ON nv.nominee_id = nh.nominee_id
WHERE nh.id = '37b87873-e1cc-4cf0-bce4-2b4bcf01185d'
GROUP BY 
  nh.id,
  nh.cycle_id,
  nc.status,
  nc.start_date,
  nc.end_date,
  p_nominee.email;