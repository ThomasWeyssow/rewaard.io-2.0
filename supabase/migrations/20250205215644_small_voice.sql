-- Vérifier chaque étape de la requête séparément

-- 1. Vérifier les cycles complétés
SELECT 
  'Cycles complétés:' as section,
  id as cycle_id,
  status,
  to_char(start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
  to_char(end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
  period,
  nomination_area_id
FROM nomination_cycles
WHERE status = 'completed'
ORDER BY end_date DESC;

-- 2. Vérifier les nominations dans l'historique
SELECT 
  'Nominations dans l''historique:' as section,
  nh.id as nomination_id,
  nh.cycle_id,
  nh.voter_id,
  nh.nominee_id,
  nh.selected_areas,
  to_char(nh.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as created_at
FROM nomination_history nh
ORDER BY nh.created_at DESC;

-- 3. Vérifier les validations
SELECT 
  'Validations:' as section,
  nv.validator_id,
  nv.nominee_id,
  to_char(nv.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as created_at
FROM nomination_validations nv
ORDER BY nv.created_at DESC;

-- 4. Vérifier la jointure entre cycles et nominations
SELECT 
  'Jointure cycles-nominations:' as section,
  nc.id as cycle_id,
  nc.status as cycle_status,
  to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_start,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_end,
  COUNT(nh.id) as nominations_count,
  COUNT(DISTINCT nh.nominee_id) as unique_nominees
FROM nomination_cycles nc
LEFT JOIN nomination_history nh ON nh.cycle_id = nc.id
WHERE nc.status = 'completed'
GROUP BY nc.id, nc.status, nc.start_date, nc.end_date
ORDER BY nc.end_date DESC;

-- 5. Vérifier les détails des nominations pour le dernier cycle
WITH last_cycle AS (
  SELECT id as cycle_id
  FROM nomination_cycles
  WHERE status = 'completed'
  ORDER BY end_date DESC
  LIMIT 1
)
SELECT 
  'Nominations du dernier cycle:' as section,
  nh.id as nomination_id,
  p_voter.email as voter_email,
  p_nominee.email as nominee_email,
  p_nominee.department as nominee_department,
  nh.selected_areas,
  nh.justification,
  COUNT(nv.validator_id) as validation_count
FROM last_cycle lc
JOIN nomination_history nh ON nh.cycle_id = lc.cycle_id
JOIN profiles p_voter ON p_voter.id = nh.voter_id
JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
LEFT JOIN nomination_validations nv ON nv.nominee_id = nh.nominee_id
GROUP BY 
  nh.id,
  p_voter.email,
  p_nominee.email,
  p_nominee.department,
  nh.selected_areas,
  nh.justification;