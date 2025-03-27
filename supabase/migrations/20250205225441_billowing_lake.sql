-- Transférer le cycle clôturé dans nomination_cycles
WITH cycle_data AS (
  SELECT 
    '92d0b59a-0985-4f1a-bc0b-226cbd132b34'::uuid as id,
    s.ongoing_nomination_start_date as start_date,
    s.ongoing_nomination_end_date as end_date,
    s.ongoing_nomination_period as period,
    s.ongoing_nomination_area_id as nomination_area_id
  FROM settings s
  WHERE s.ongoing_nomination_start_date IS NOT NULL
    AND s.ongoing_nomination_end_date IS NOT NULL
)
INSERT INTO nomination_cycles (
  id,
  start_date,
  end_date,
  period,
  nomination_area_id,
  status
)
SELECT 
  cd.id,
  cd.start_date,
  cd.end_date,
  cd.period,
  cd.nomination_area_id,
  'completed'
FROM cycle_data cd
WHERE NOT EXISTS (
  SELECT 1 
  FROM nomination_cycles 
  WHERE id = '92d0b59a-0985-4f1a-bc0b-226cbd132b34'::uuid
);

-- Transférer les nominations associées dans nomination_history
WITH cycle_id AS (
  SELECT '92d0b59a-0985-4f1a-bc0b-226cbd132b34'::uuid as id
)
INSERT INTO nomination_history (
  cycle_id,
  voter_id,
  nominee_id,
  selected_areas,
  justification,
  remarks,
  nomination_area_id
)
SELECT 
  ci.id,
  n.voter_id,
  n.nominee_id,
  n.selected_areas,
  n.justification,
  n.remarks,
  s.ongoing_nomination_area_id
FROM nominations n
CROSS JOIN settings s
CROSS JOIN cycle_id ci
WHERE NOT EXISTS (
  SELECT 1 
  FROM nomination_history nh 
  WHERE nh.cycle_id = ci.id
    AND nh.voter_id = n.voter_id
    AND nh.nominee_id = n.nominee_id
);

-- Supprimer les nominations transférées
WITH cycle_id AS (
  SELECT '92d0b59a-0985-4f1a-bc0b-226cbd132b34'::uuid as id
)
DELETE FROM nominations n
WHERE EXISTS (
  SELECT 1 
  FROM nomination_history nh 
  CROSS JOIN cycle_id ci
  WHERE nh.cycle_id = ci.id
    AND nh.voter_id = n.voter_id
    AND nh.nominee_id = n.nominee_id
);

-- Vérifier l'état final
SELECT 
  'État du cycle:' as section,
  nc.id as cycle_id,
  nc.status,
  to_char(nc.start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
  COUNT(nh.id) as nominations_count
FROM nomination_cycles nc
LEFT JOIN nomination_history nh ON nh.cycle_id = nc.id
WHERE nc.id = '92d0b59a-0985-4f1a-bc0b-226cbd132b34'::uuid
GROUP BY nc.id, nc.status, nc.start_date, nc.end_date;