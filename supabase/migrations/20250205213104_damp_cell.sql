-- Vérifier la logique de récupération des nominations pour la page Review
WITH last_completed_cycle AS (
  SELECT 
    nc.id,
    nc.start_date,
    nc.end_date,
    nc.period,
    nc.nomination_area_id,
    nc.status
  FROM nomination_cycles nc
  WHERE nc.status = 'completed'
  ORDER BY nc.end_date DESC
  LIMIT 1
),
cycle_nominations AS (
  SELECT 
    nh.*,
    p_voter.email as voter_email,
    p_voter.first_name as voter_first_name,
    p_voter.last_name as voter_last_name,
    p_nominee.email as nominee_email,
    p_nominee.first_name as nominee_first_name,
    p_nominee.last_name as nominee_last_name,
    p_nominee.department as nominee_department,
    lcc.start_date as cycle_start,
    lcc.end_date as cycle_end,
    na.category as nomination_area
  FROM last_completed_cycle lcc
  LEFT JOIN nomination_history nh ON nh.cycle_id = lcc.id
  LEFT JOIN profiles p_voter ON p_voter.id = nh.voter_id
  LEFT JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
  LEFT JOIN nomination_areas na ON na.id = lcc.nomination_area_id
)
SELECT 
  'État du dernier cycle complété:' as section,
  cycle_start,
  cycle_end,
  nomination_area,
  COUNT(DISTINCT id) as total_nominations,
  ARRAY_AGG(DISTINCT nominee_email) as nominees,
  EXISTS (
    SELECT 1 
    FROM cycle_nominations 
    WHERE id = 'fc8def30-01a3-404f-882b-9eef465ae421'
  ) as target_nomination_exists
FROM cycle_nominations
GROUP BY cycle_start, cycle_end, nomination_area;