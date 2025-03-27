-- Requête mise à jour pour la page Review
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
    ARRAY_AGG(DISTINCT nh.id) as nomination_ids
  FROM last_completed_cycle lcc
  JOIN nomination_history nh ON nh.cycle_id = lcc.cycle_id
  JOIN profiles p ON p.id = nh.nominee_id
  LEFT JOIN nomination_validations nv ON nv.nominee_id = nh.nominee_id
  GROUP BY 
    nh.nominee_id,
    p.first_name,
    p.last_name,
    p.department,
    p.avatar_url
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
  lcc.cycle_id,
  lcc.start_date,
  lcc.end_date,
  lcc.area_category,
  lcc.area_details,
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
FROM last_completed_cycle lcc
CROSS JOIN nominee_stats ns
GROUP BY 
  lcc.cycle_id,
  lcc.start_date,
  lcc.end_date,
  lcc.area_category,
  lcc.area_details;