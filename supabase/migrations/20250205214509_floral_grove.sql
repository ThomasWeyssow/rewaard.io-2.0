-- Vérifier la structure complète des données
WITH cycle_info AS (
  SELECT 
    nc.id as cycle_id,
    nc.status,
    to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
    to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
    nc.period,
    na.category as area_category,
    na.areas as area_details
  FROM nomination_cycles nc
  LEFT JOIN nomination_areas na ON na.id = nc.nomination_area_id
  WHERE nc.status = 'completed'
  ORDER BY nc.end_date DESC
  LIMIT 1
),
nominations_by_nominee AS (
  SELECT 
    p_nominee.id as nominee_id,
    p_nominee.first_name || ' ' || p_nominee.last_name as nominee_name,
    p_nominee.department as nominee_department,
    p_nominee.avatar_url as nominee_avatar,
    COUNT(DISTINCT nh.id) as nomination_count,
    COUNT(DISTINCT nv.validator_id) as validation_count,
    ARRAY_AGG(DISTINCT nh.id) as nomination_ids,
    ARRAY_AGG(DISTINCT nv.validator_id) as validator_ids,
    ci.cycle_id,
    ci.start_date,
    ci.end_date,
    ci.area_category,
    ci.area_details
  FROM cycle_info ci
  JOIN nomination_history nh ON nh.cycle_id = ci.cycle_id
  JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
  LEFT JOIN nomination_validations nv ON 
    nv.nominee_id = nh.nominee_id AND
    nv.validator_id IS NOT NULL
  GROUP BY 
    p_nominee.id,
    p_nominee.first_name,
    p_nominee.last_name,
    p_nominee.department,
    p_nominee.avatar_url,
    ci.cycle_id,
    ci.start_date,
    ci.end_date,
    ci.area_category,
    ci.area_details
  ORDER BY 
    validation_count DESC,
    nomination_count DESC
  LIMIT 6
),
nomination_details AS (
  SELECT 
    nh.id as nomination_id,
    nh.voter_id,
    p_voter.first_name || ' ' || p_voter.last_name as voter_name,
    p_voter.department as voter_department,
    p_voter.avatar_url as voter_avatar,
    nh.nominee_id,
    nh.selected_areas,
    nh.justification,
    nh.remarks,
    to_char(nh.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as created_at
  FROM nomination_history nh
  JOIN profiles p_voter ON p_voter.id = nh.voter_id
  WHERE nh.nominee_id IN (SELECT nominee_id FROM nominations_by_nominee)
)
SELECT 
  'Top 6 nominés:' as section,
  nbn.*,
  'Détails des nominations:' as details_section,
  ARRAY_AGG(
    json_build_object(
      'nomination_id', nd.nomination_id,
      'voter_name', nd.voter_name,
      'voter_department', nd.voter_department,
      'voter_avatar', nd.voter_avatar,
      'selected_areas', nd.selected_areas,
      'justification', nd.justification,
      'remarks', nd.remarks,
      'created_at', nd.created_at
    )
  ) as nominations
FROM nominations_by_nominee nbn
LEFT JOIN nomination_details nd ON nd.nominee_id = nbn.nominee_id
GROUP BY 
  nbn.nominee_id,
  nbn.nominee_name,
  nbn.nominee_department,
  nbn.nominee_avatar,
  nbn.nomination_count,
  nbn.validation_count,
  nbn.nomination_ids,
  nbn.validator_ids,
  nbn.cycle_id,
  nbn.start_date,
  nbn.end_date,
  nbn.area_category,
  nbn.area_details;