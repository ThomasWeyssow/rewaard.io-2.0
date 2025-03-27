-- Exécuter la fonction du cron
SELECT check_and_update_nomination_cycles();

-- Vérifier l'état des nominations et de l'historique après l'exécution
SELECT 'État des nominations:' as section,
COUNT(*) as count,
'nominations actives' as description
FROM nominations
UNION ALL
SELECT 'État des nominations:',
COUNT(*) as count,
'nominations en historique' as description
FROM nomination_history;

-- Vérifier les cycles de nomination
SELECT 
  'État des cycles:' as section,
  status,
  to_char(start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as start_date,
  to_char(end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as end_date,
  period,
  nomination_area_id
FROM nomination_cycles
ORDER BY 
  CASE status
    WHEN 'next' THEN 1
    WHEN 'ongoing' THEN 2
    WHEN 'completed' THEN 3
  END;

-- Vérifier les paramètres de settings
SELECT 
  'État des settings:' as section,
  to_char(next_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_start,
  to_char(next_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as next_end,
  to_char(ongoing_nomination_start_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris', 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  next_nomination_period,
  ongoing_nomination_period
FROM settings;