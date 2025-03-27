-- Vérifier l'état actuel de la nomination et du cycle
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
  'État actuel de la nomination:' as section,
  *
FROM nomination_check;

-- Vérifier les contraintes sur la table nominations
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'nominations'::regclass;

-- Vérifier les politiques RLS
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'nominations';

-- Recréer la nomination avec les données correctes
INSERT INTO nominations (
  id,
  voter_id,
  nominee_id,
  selected_areas,
  justification,
  remarks
)
SELECT 
  'c95aee09-bd5b-417a-914a-5369e0b28cd6',
  (SELECT id FROM profiles WHERE email = 'nicolas@gmail.com'),
  (SELECT id FROM profiles WHERE email = 'emma.laurent@company.com'),
  ARRAY['Vision stratégique', 'Innovation'],
  'Excellente contribution sur le projet Hero Program',
  'A démontré un leadership exceptionnel'
WHERE NOT EXISTS (
  SELECT 1 
  FROM nominations 
  WHERE id = 'c95aee09-bd5b-417a-914a-5369e0b28cd6'
);

-- Vérifier l'état final
SELECT 
  'État final:' as section,
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
WHERE n.id = 'c95aee09-bd5b-417a-914a-5369e0b28cd6';