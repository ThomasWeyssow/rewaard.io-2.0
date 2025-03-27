-- Vérifier la structure actuelle des données
WITH last_cycle AS (
  SELECT 
    nc.id as cycle_id,
    nc.start_date,
    nc.end_date,
    nc.nomination_area_id,
    na.category as area_category,
    na.areas as area_details
  FROM nomination_cycles nc
  LEFT JOIN nomination_areas na ON na.id = nc.nomination_area_id
  WHERE nc.status = 'completed'
  ORDER BY nc.end_date DESC
  LIMIT 1
),
cycle_nominations AS (
  SELECT 
    nh.id as nomination_id,
    nh.voter_id,
    nh.nominee_id,
    nh.selected_areas,
    nh.justification,
    nh.remarks,
    p_voter.first_name as voter_first_name,
    p_voter.last_name as voter_last_name,
    p_voter.department as voter_department,
    p_voter.avatar_url as voter_avatar,
    p_nominee.first_name as nominee_first_name,
    p_nominee.last_name as nominee_last_name,
    p_nominee.department as nominee_department,
    p_nominee.avatar_url as nominee_avatar,
    lc.area_category,
    lc.area_details,
    lc.start_date,
    lc.end_date
  FROM last_cycle lc
  JOIN nomination_history nh ON nh.cycle_id = lc.cycle_id
  JOIN profiles p_voter ON p_voter.id = nh.voter_id
  JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
)
SELECT 
  'État des nominations à valider:' as section,
  COUNT(*) as total_nominations,
  ARRAY_AGG(DISTINCT nominee_id) as nominee_ids,
  ARRAY_AGG(DISTINCT nomination_id) as nomination_ids,
  to_char(MIN(start_date) AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_start,
  to_char(MAX(end_date) AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_end,
  area_category,
  area_details
FROM cycle_nominations
GROUP BY area_category, area_details;