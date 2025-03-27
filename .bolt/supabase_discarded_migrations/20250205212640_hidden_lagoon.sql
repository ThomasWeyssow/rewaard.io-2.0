-- Vérifier les nominations du dernier cycle complété
WITH last_completed_cycle AS (
  SELECT id
  FROM nomination_cycles
  WHERE status = 'completed'
  ORDER BY end_date DESC
  LIMIT 1
)
SELECT 
  'Nominations du cycle:' as section,
  p_voter.email as voter_email,
  p_nominee.email as nominee_email,
  nh.selected_areas,
  nh.justification,
  nh.remarks,
  to_char(nh.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as nomination_date
FROM nomination_history nh
JOIN last_completed_cycle lcc ON nh.cycle_id = lcc.id
JOIN profiles p_voter ON p_voter.id = nh.voter_id
JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
ORDER BY nh.created_at DESC;