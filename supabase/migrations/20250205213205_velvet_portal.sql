-- Vérifier l'état du cycle et de la nomination
WITH cycle_check AS (
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
nomination_check AS (
  SELECT 
    nh.*,
    p_voter.email as voter_email,
    p_nominee.email as nominee_email,
    p_nominee.department as nominee_department
  FROM nomination_history nh
  JOIN profiles p_voter ON p_voter.id = nh.voter_id
  JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
  WHERE nh.id = 'fc8def30-01a3-404f-882b-9eef465ae421'
)
SELECT 
  'État du cycle:' as section,
  cc.*,
  'État de la nomination:' as nomination_section,
  nc.id as nomination_id,
  nc.voter_email,
  nc.nominee_email,
  nc.nominee_department,
  nc.cycle_id as nomination_cycle_id,
  nc.selected_areas,
  nc.justification,
  nc.remarks
FROM cycle_check cc
LEFT JOIN nomination_check nc ON nc.cycle_id = cc.cycle_id;

-- Vérifier si le cycle est bien marqué comme complété
UPDATE nomination_cycles
SET status = 'completed'
WHERE id = '3d74474f-6d27-48e7-959f-401fa3a186d9'
AND status != 'completed';