-- Vérifier le dernier cycle complété et ses nominations
WITH last_completed_cycle AS (
  SELECT 
    nc.id,
    nc.start_date,
    nc.end_date,
    nc.period,
    nc.nomination_area_id
  FROM nomination_cycles nc
  WHERE nc.status = 'completed'
  ORDER BY nc.end_date DESC
  LIMIT 1
)
SELECT 
  'Dernier cycle complété:' as section,
  to_char(lcc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
  to_char(lcc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
  lcc.period,
  nh.voter_id,
  p_voter.email as voter_email,
  nh.nominee_id,
  p_nominee.email as nominee_email,
  nh.selected_areas,
  nh.justification,
  nh.remarks
FROM last_completed_cycle lcc
LEFT JOIN nomination_history nh ON nh.cycle_id = lcc.id
LEFT JOIN profiles p_voter ON p_voter.id = nh.voter_id
LEFT JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
ORDER BY nh.created_at DESC;