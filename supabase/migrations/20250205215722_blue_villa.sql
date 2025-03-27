-- 1. Vérifier les cycles et leur statut
SELECT 
  'État des cycles:' as section,
  status,
  COUNT(*) as count,
  MIN(to_char(start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS')) as earliest_start,
  MAX(to_char(end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS')) as latest_end
FROM nomination_cycles
GROUP BY status;

-- 2. Vérifier les nominations et leur cycle_id
SELECT 
  'État des nominations:' as section,
  COUNT(*) as total_nominations,
  COUNT(DISTINCT cycle_id) as unique_cycles,
  COUNT(*) FILTER (WHERE cycle_id IS NULL) as nominations_without_cycle
FROM nomination_history;

-- 3. Vérifier la correspondance entre cycles et nominations
SELECT 
  'Correspondance cycles-nominations:' as section,
  nc.id as cycle_id,
  nc.status,
  to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_start,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_end,
  COUNT(nh.id) as nominations_in_cycle
FROM nomination_cycles nc
LEFT JOIN nomination_history nh ON nh.cycle_id = nc.id
GROUP BY nc.id, nc.status, nc.start_date, nc.end_date
ORDER BY nc.end_date DESC;

-- 4. Vérifier les nominations sans cycle valide
SELECT 
  'Nominations orphelines:' as section,
  nh.id as nomination_id,
  nh.cycle_id,
  p_voter.email as voter_email,
  p_nominee.email as nominee_email,
  to_char(nh.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as created_at
FROM nomination_history nh
JOIN profiles p_voter ON p_voter.id = nh.voter_id
JOIN profiles p_nominee ON p_nominee.id = nh.nominee_id
LEFT JOIN nomination_cycles nc ON nc.id = nh.cycle_id
WHERE nc.id IS NULL OR nc.status != 'completed';