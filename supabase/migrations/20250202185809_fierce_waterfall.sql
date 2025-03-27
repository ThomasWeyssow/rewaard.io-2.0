-- Exécuter la fonction
SELECT check_and_update_nomination_cycles();

-- Vérifier l'état avant et après l'exécution
WITH before_state AS (
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
  'État actuel des cycles de nomination:' as info,
  next_start as "Date début prochain",
  next_end as "Date fin prochain",
  ongoing_start as "Date début en cours",
  ongoing_end as "Date fin en cours",
  next_nomination_period as "Période prochain",
  ongoing_nomination_period as "Période en cours",
  next_nomination_area_id as "Zone prochain",
  ongoing_nomination_area_id as "Zone en cours"
FROM before_state;

-- Vérifier les conditions de transition
SELECT 
  CURRENT_TIMESTAMP as "Heure actuelle",
  next_nomination_start_date <= CURRENT_TIMESTAMP as "Démarrer nouveau cycle ?",
  ongoing_nomination_start_date IS NULL as "Pas de cycle en cours ?",
  ongoing_nomination_end_date < CURRENT_TIMESTAMP as "Cycle en cours terminé ?"
FROM settings;