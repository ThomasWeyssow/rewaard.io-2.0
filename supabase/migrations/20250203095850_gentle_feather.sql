-- Exécuter manuellement la fonction check_and_update_nomination_cycles
SELECT check_and_update_nomination_cycles();

-- Vérifier l'état des cycles et les conditions de transition
WITH cycle_state AS (
  SELECT 
    to_char(next_nomination_start_date::date, 'YYYY-MM-DD') as next_start,
    to_char(next_nomination_end_date::date, 'YYYY-MM-DD') as next_end,
    to_char(ongoing_nomination_start_date::date, 'YYYY-MM-DD') as ongoing_start,
    to_char(ongoing_nomination_end_date::date, 'YYYY-MM-DD') as ongoing_end,
    next_nomination_period,
    ongoing_nomination_period,
    next_nomination_area_id,
    ongoing_nomination_area_id,
    CURRENT_TIMESTAMP as current_time,
    next_nomination_start_date <= CURRENT_TIMESTAMP as should_start_new_cycle,
    ongoing_nomination_start_date IS NULL as no_ongoing_cycle,
    CASE 
      WHEN ongoing_nomination_end_date IS NOT NULL 
      THEN ongoing_nomination_end_date < CURRENT_TIMESTAMP 
      ELSE false 
    END as ongoing_cycle_finished
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
  ongoing_nomination_area_id as "Zone - En cours",
  to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') as "Heure actuelle",
  should_start_new_cycle as "Démarrer nouveau cycle ?",
  no_ongoing_cycle as "Pas de cycle en cours ?",
  ongoing_cycle_finished as "Cycle en cours terminé ?"
FROM cycle_state;