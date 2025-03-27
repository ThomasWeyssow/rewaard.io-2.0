-- Vérifier l'état de la nomination spécifique
WITH nomination_check AS (
  SELECT 
    n.*,
    p_voter.email as voter_email,
    p_nominee.email as nominee_email,
    s.ongoing_nomination_start_date,
    s.ongoing_nomination_end_date,
    s.ongoing_cycle_id
  FROM nominations n
  JOIN profiles p_voter ON p_voter.id = n.voter_id
  JOIN profiles p_nominee ON p_nominee.id = n.nominee_id
  CROSS JOIN settings s
  WHERE n.id = 'c95aee09-bd5b-417a-914a-5369e0b28cd6'
)
SELECT 
  'État de la nomination:' as section,
  *
FROM nomination_check;

-- Vérifier l'état actuel du cycle en cours
SELECT 
  'État du cycle en cours:' as section,
  ongoing_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end
FROM settings;

-- Mettre à jour la nomination avec le cycle en cours si nécessaire
UPDATE nominations n
SET cycle_id = s.ongoing_cycle_id
FROM settings s
WHERE n.id = 'c95aee09-bd5b-417a-914a-5369e0b28cd6'
  AND s.ongoing_cycle_id IS NOT NULL;

-- Vérifier l'état final
SELECT 
  'État final de la nomination:' as section,
  n.*,
  p_voter.email as voter_email,
  p_nominee.email as nominee_email,
  s.ongoing_nomination_start_date,
  s.ongoing_nomination_end_date
FROM nominations n
JOIN profiles p_voter ON p_voter.id = n.voter_id
JOIN profiles p_nominee ON p_nominee.id = n.nominee_id
CROSS JOIN settings s
WHERE n.id = 'c95aee09-bd5b-417a-914a-5369e0b28cd6';