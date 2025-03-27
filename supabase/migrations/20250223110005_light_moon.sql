-- Vérifier la structure actuelle des données
WITH last_completed_cycle AS (
  SELECT 
    nc.id as cycle_id,
    nc.start_date,
    nc.end_date,
    nc.status
  FROM nomination_cycles nc
  WHERE nc.status = 'completed'
  ORDER BY nc.end_date DESC
  LIMIT 1
),
validation_check AS (
  SELECT 
    nv.id as validation_id,
    nv.validator_id,
    nv.nominee_id,
    nv.cycle_id,
    p_validator.email as validator_email,
    p_nominee.email as nominee_email,
    lcc.cycle_id as expected_cycle_id
  FROM nomination_validations nv
  JOIN profiles p_validator ON p_validator.id = nv.validator_id
  JOIN profiles p_nominee ON p_nominee.id = nv.nominee_id
  CROSS JOIN last_completed_cycle lcc
)
SELECT 
  'État des validations:' as section,
  vc.*,
  CASE 
    WHEN vc.cycle_id = vc.expected_cycle_id THEN 'OK'
    ELSE 'MISMATCH'
  END as cycle_status
FROM validation_check vc;

-- Mettre à jour les validations avec le bon cycle_id si nécessaire
WITH last_completed_cycle AS (
  SELECT 
    nc.id as cycle_id,
    nc.start_date,
    nc.end_date
  FROM nomination_cycles nc
  WHERE nc.status = 'completed'
  ORDER BY nc.end_date DESC
  LIMIT 1
)
UPDATE nomination_validations nv
SET cycle_id = lcc.cycle_id
FROM last_completed_cycle lcc
WHERE nv.cycle_id != lcc.cycle_id
  OR nv.cycle_id IS NULL;

-- Vérifier l'état final
SELECT 
  'État final:' as section,
  nv.id as validation_id,
  nv.cycle_id,
  nc.status as cycle_status,
  to_char(nc.end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as cycle_end,
  p_validator.email as validator_email,
  p_nominee.email as nominee_email
FROM nomination_validations nv
JOIN nomination_cycles nc ON nc.id = nv.cycle_id
JOIN profiles p_validator ON p_validator.id = nv.validator_id
JOIN profiles p_nominee ON p_nominee.id = nv.nominee_id
ORDER BY nc.end_date DESC;