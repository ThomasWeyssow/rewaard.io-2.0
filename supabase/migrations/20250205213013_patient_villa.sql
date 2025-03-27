-- Vérifier l'état actuel des cycles et nominations
WITH cycle_info AS (
  SELECT 
    nc.id as cycle_id,
    nc.status,
    to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
    to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
    nc.period,
    na.category as nomination_area
  FROM nomination_cycles nc
  LEFT JOIN nomination_areas na ON na.id = nc.nomination_area_id
  WHERE nc.id = '3d74474f-6d27-48e7-959f-401fa3a186d9'
),
nomination_info AS (
  SELECT 
    nh.id as nomination_id,
    p_voter.email as voter_email,
    p_nominee.email as nominee_email,
    nh.selected_areas,
    nh.justification,
    nh.remarks,
    to_char(nh.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as created_at
  FROM nomination_history nh
  JOIN profiles p_voter ON p_voter.id = nh.voter_id
  JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
  WHERE nh.id = 'fc8def30-01a3-404f-882b-9eef465ae421'
)
SELECT 
  'État du cycle:' as section,
  ci.*,
  'État de la nomination:' as nomination_section,
  ni.*
FROM cycle_info ci
CROSS JOIN nomination_info ni;