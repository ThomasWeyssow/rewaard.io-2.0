-- Vérifier la requête de la page Review
WITH last_completed_cycle AS (
  SELECT 
    nc.id as cycle_id,
    nc.start_date,
    nc.end_date,
    nc.period,
    nc.nomination_area_id,
    na.category as area_category,
    na.areas as area_details
  FROM nomination_cycles nc
  LEFT JOIN nomination_areas na ON na.id = nc.nomination_area_id
  WHERE nc.status = 'completed'
  ORDER BY nc.end_date DESC
  LIMIT 1
),
nominee_stats AS (
  SELECT 
    nh.nominee_id,
    p.first_name,
    p.last_name,
    p.department,
    p.avatar_url,
    COUNT(DISTINCT nh.id) as nomination_count,
    COUNT(DISTINCT nv.validator_id) as validation_count,
    ARRAY_AGG(DISTINCT nv.validator_id) as validator_ids,
    ARRAY_AGG(DISTINCT nh.id) as nomination_ids,
    lcc.cycle_id,
    lcc.start_date,
    lcc.end_date,
    lcc.area_category,
    lcc.area_details
  FROM last_completed_cycle lcc
  JOIN nomination_history nh ON nh.cycle_id = lcc.cycle_id
  JOIN profiles p ON p.id = nh.nominee_id
  LEFT JOIN nomination_validations nv ON 
    nv.nominee_id = nh.nominee_id 
    AND nv.cycle_id = lcc.cycle_id  -- Ajout de la condition sur le cycle_id
  GROUP BY 
    nh.nominee_id,
    p.first_name,
    p.last_name,
    p.department,
    p.avatar_url,
    lcc.cycle_id,
    lcc.start_date,
    lcc.end_date,
    lcc.area_category,
    lcc.area_details
  ORDER BY 
    COUNT(DISTINCT nv.validator_id) DESC,
    COUNT(DISTINCT nh.id) DESC
)
SELECT 
  'État de la requête Review:' as section,
  ns.cycle_id,
  ns.nominee_id,
  ns.first_name || ' ' || ns.last_name as nominee_name,
  ns.validation_count,
  ns.validator_ids,
  to_char(ns.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_start,
  to_char(ns.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_end
FROM nominee_stats ns;

-- Vérifier les validations existantes
SELECT 
  'État des validations:' as section,
  nv.id as validation_id,
  nv.cycle_id,
  nv.validator_id,
  nv.nominee_id,
  p_validator.email as validator_email,
  p_nominee.email as nominee_email,
  nc.status as cycle_status,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_end
FROM nomination_validations nv
JOIN profiles p_validator ON p_validator.id = nv.validator_id
JOIN profiles p_nominee ON p_nominee.id = nv.nominee_id
LEFT JOIN nomination_cycles nc ON nc.id = nv.cycle_id
ORDER BY nc.end_date DESC;