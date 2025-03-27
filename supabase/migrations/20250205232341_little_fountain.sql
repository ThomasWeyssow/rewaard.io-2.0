-- Vérifier si la nomination existe
SELECT 
  'État de la nomination:' as section,
  n.*,
  p_voter.email as voter_email,
  p_nominee.email as nominee_email,
  s.ongoing_nomination_start_date,
  s.ongoing_nomination_end_date
FROM nominations n
JOIN profiles p_voter ON p_voter.id = n.voter_id
JOIN profiles p_nominee ON p_nominee.id = n.nominee_id
CROSS JOIN settings s
WHERE n.id = 'c7c51e87-d12b-46b7-b355-2b391b5c48b5';

-- Vérifier l'état du cycle en cours
SELECT 
  'État du cycle en cours:' as section,
  ongoing_cycle_id,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end
FROM settings;

-- Vérifier les politiques RLS actuelles
SELECT 
  'Politiques RLS:' as section,
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