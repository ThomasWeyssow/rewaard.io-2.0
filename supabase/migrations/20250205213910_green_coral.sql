-- Vérifier en détail la nomination et son cycle
WITH nomination_details AS (
  SELECT 
    nh.id as nomination_id,
    nh.cycle_id,
    nh.voter_id,
    nh.nominee_id,
    nh.selected_areas,
    nh.justification,
    nh.remarks,
    p_voter.email as voter_email,
    p_nominee.email as nominee_email,
    p_nominee.department as nominee_department,
    to_char(nh.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as created_at
  FROM nomination_history nh
  JOIN profiles p_voter ON p_voter.id = nh.voter_id
  JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
  WHERE nh.id = 'fc8def30-01a3-404f-882b-9eef465ae421'
),
cycle_details AS (
  SELECT 
    nc.id as cycle_id,
    nc.status,
    to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
    to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
    nc.period,
    na.category as area_category
  FROM nomination_cycles nc
  LEFT JOIN nomination_areas na ON na.id = nc.nomination_area_id
  WHERE nc.id = '3d74474f-6d27-48e7-959f-401fa3a186d9'
)
SELECT 
  'Détails de la nomination:' as section,
  nd.*,
  'Détails du cycle:' as cycle_section,
  cd.*,
  CASE 
    WHEN nd.cycle_id = cd.cycle_id THEN 'Oui'
    ELSE 'Non'
  END as cycles_match
FROM nomination_details nd
CROSS JOIN cycle_details cd;

-- Vérifier si la nomination est correctement liée au cycle
SELECT 
  'État de la liaison nomination-cycle:' as section,
  COUNT(*) as total_nominations_for_cycle
FROM nomination_history
WHERE cycle_id = '3d74474f-6d27-48e7-959f-401fa3a186d9';

-- Vérifier l'état du cycle
SELECT 
  'État du cycle:' as section,
  status,
  to_char(start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
  to_char(end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date
FROM nomination_cycles
WHERE id = '3d74474f-6d27-48e7-959f-401fa3a186d9';