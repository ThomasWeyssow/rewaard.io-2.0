-- Vérifier la structure actuelle des données
WITH last_cycles AS (
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
    lc.cycle_id,
    lc.start_date,
    lc.end_date,
    lc.area_category,
    lc.area_details
  FROM last_cycles lc
  JOIN nomination_history nh ON nh.cycle_id = lc.cycle_id
  JOIN profiles p ON p.id = nh.nominee_id
  LEFT JOIN nomination_validations nv ON nv.nominee_id = nh.nominee_id
  GROUP BY 
    nh.nominee_id,
    p.first_name,
    p.last_name,
    p.department,
    p.avatar_url,
    lc.cycle_id,
    lc.start_date,
    lc.end_date,
    lc.area_category,
    lc.area_details
  ORDER BY 
    COUNT(DISTINCT nv.validator_id) DESC,
    COUNT(DISTINCT nh.id) DESC
),
nomination_details AS (
  SELECT 
    nh.id as nomination_id,
    nh.nominee_id,
    nh.voter_id,
    p.first_name as voter_first_name,
    p.last_name as voter_last_name,
    p.department as voter_department,
    p.avatar_url as voter_avatar,
    nh.selected_areas,
    nh.justification,
    nh.remarks,
    to_char(nh.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as created_at
  FROM nomination_history nh
  JOIN profiles p ON p.id = nh.voter_id
  WHERE nh.nominee_id IN (SELECT nominee_id FROM nominee_stats)
)
SELECT 
  'État des nominations:' as section,
  json_agg(
    json_build_object(
      'nominee_id', ns.nominee_id,
      'first_name', ns.first_name,
      'last_name', ns.last_name,
      'department', ns.department,
      'avatar_url', ns.avatar_url,
      'nomination_count', ns.nomination_count,
      'validation_count', ns.validation_count,
      'validator_ids', ns.validator_ids,
      'nominations', (
        SELECT json_agg(row_to_json(nd))
        FROM nomination_details nd
        WHERE nd.nominee_id = ns.nominee_id
      )
    )
  ) as nominees
FROM nominee_stats ns
GROUP BY 
  ns.cycle_id,
  ns.start_date,
  ns.end_date,
  ns.area_category,
  ns.area_details;