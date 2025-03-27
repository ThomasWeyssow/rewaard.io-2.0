-- Exécuter manuellement la fonction check_and_update_nomination_cycles
SELECT check_and_update_nomination_cycles();

-- Vérifier l'état des cycles après l'exécution
WITH cycle_state AS (
  SELECT 
    to_char(next_nomination_start_date, 'YYYY-MM-DD HH24:MI:SS') as next_start,
    to_char(next_nomination_end_date, 'YYYY-MM-DD HH24:MI:SS') as next_end,
    to_char(ongoing_nomination_start_date, 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
    to_char(ongoing_nomination_end_date, 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
    next_nomination_period,
    ongoing_nomination_period,
    next_nomination_area_id,
    ongoing_nomination_area_id
  FROM settings
)
SELECT 
  'État des cycles de nomination:' as info,
  next_start as "Prochain cycle - Début",
  next_end as "Prochain cycle - Fin",
  ongoing_start as "Cycle en cours - Début",
  ongoing_end as "Cycle en cours - Fin",
  next_nomination_period as "Période - Prochain",
  ongoing_nomination_period as "Période - En cours",
  next_nomination_area_id as "Zone - Prochain",
  ongoing_nomination_area_id as "Zone - En cours"
FROM cycle_state;