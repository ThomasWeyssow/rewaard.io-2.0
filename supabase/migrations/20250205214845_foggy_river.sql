-- Vérifier la structure des données pour la page Review
WITH cycle_stats AS (
  SELECT 
    nc.id as cycle_id,
    nc.status,
    to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
    to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
    nc.period,
    na.category as area_category,
    COUNT(DISTINCT nh.id) as nomination_count,
    COUNT(DISTINCT nh.nominee_id) as nominee_count
  FROM nomination_cycles nc
  LEFT JOIN nomination_areas na ON na.id = nc.nomination_area_id
  LEFT JOIN nomination_history nh ON nh.cycle_id = nc.id
  WHERE nc.status = 'completed'
  GROUP BY nc.id, nc.status, nc.start_date, nc.end_date, nc.period, na.category
  ORDER BY nc.end_date DESC
  LIMIT 1
),
nominee_stats AS (
  SELECT 
    nh.nominee_id,
    p.first_name || ' ' || p.last_name as nominee_name,
    p.department as nominee_department,
    p.avatar_url as nominee_avatar,
    COUNT(DISTINCT nh.id) as nomination_count,
    COUNT(DISTINCT nv.validator_id) as validation_count,
    ARRAY_AGG(DISTINCT nv.validator_id) as validator_ids,
    ARRAY_AGG(DISTINCT nh.id) as nomination_ids
  FROM cycle_stats cs
  JOIN nomination_history nh ON nh.cycle_id = cs.cycle_id
  JOIN profiles p ON p.id = nh.nominee_id
  LEFT JOIN nomination_validations nv ON nv.nominee_id = nh.nominee_id
  GROUP BY nh.nominee_id, p.first_name, p.last_name, p.department, p.avatar_url
),
cycle_summary AS (
  SELECT 
    cs.cycle_id,
    cs.status,
    cs.start_date,
    cs.end_date,
    cs.period,
    cs.area_category,
    cs.nomination_count,
    cs.nominee_count,
    (
      SELECT json_agg(row_to_json(ns))
      FROM nominee_stats ns
    ) as nominees
  FROM cycle_stats cs
)
SELECT 
  'État du dernier cycle complété:' as section,
  *
FROM cycle_summary;

-- Vérifier les détails de la nomination spécifique
SELECT 
  'Détails de la nomination recherchée:' as section,
  nh.id as nomination_id,
  nh.cycle_id,
  p_voter.email as voter_email,
  p_nominee.email as nominee_email,
  nh.selected_areas,
  nh.justification,
  nh.remarks,
  to_char(nh.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as created_at,
  nc.status as cycle_status,
  to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_start,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_end
FROM nomination_history nh
JOIN profiles p_voter ON p_voter.id = nh.voter_id
JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
LEFT JOIN nomination_cycles nc ON nc.id = nh.cycle_id
WHERE nh.id = 'fc8def30-01a3-404f-882b-9eef465ae421';