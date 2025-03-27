-- Vérifier le dernier cycle complété et ses nominations
WITH last_completed_cycle AS (
  SELECT 
    nc.id,
    nc.start_date,
    nc.end_date,
    nc.period,
    nc.nomination_area_id,
    na.category as nomination_area
  FROM nomination_cycles nc
  LEFT JOIN nomination_areas na ON na.id = nc.nomination_area_id
  WHERE nc.status = 'completed'
  ORDER BY nc.end_date DESC
  LIMIT 1
)
SELECT 
  'Dernier cycle complété:' as section,
  lcc.id as cycle_id,
  to_char(lcc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
  to_char(lcc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
  lcc.period,
  lcc.nomination_area,
  COUNT(nh.id) as total_nominations
FROM last_completed_cycle lcc
LEFT JOIN nomination_history nh ON nh.cycle_id = lcc.id
GROUP BY 
  lcc.id,
  lcc.start_date,
  lcc.end_date,
  lcc.period,
  lcc.nomination_area;