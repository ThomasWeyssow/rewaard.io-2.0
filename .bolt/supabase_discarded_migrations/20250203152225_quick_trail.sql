-- Exécuter manuellement la fonction check_and_update_nomination_cycles
SELECT check_and_update_nomination_cycles();

-- Vérifier l'état des cycles et les résultats
WITH cycle_state AS (
  SELECT 
    to_char(next_nomination_start_date, 'YYYY-MM-DD HH24:MI:SS') as next_start,
    to_char(next_nomination_end_date, 'YYYY-MM-DD HH24:MI:SS') as next_end,
    to_char(ongoing_nomination_start_date, 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
    to_char(ongoing_nomination_end_date, 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
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

-- Afficher les derniers résultats de nomination (top 6)
SELECT 
  to_char(nr.cycle_start_date, 'YYYY-MM-DD HH24:MI:SS') as cycle_start,
  to_char(nr.cycle_end_date, 'YYYY-MM-DD HH24:MI:SS') as cycle_end,
  p.first_name || ' ' || p.last_name as nominee_name,
  nr.nomination_count,
  -- Compter les validations pour ce cycle
  (
    SELECT COUNT(DISTINCT validator_id)
    FROM nomination_validations v
    WHERE v.nominee_id = nr.nominee_id
    AND v.cycle_start_date = nr.cycle_start_date
    AND v.cycle_end_date = nr.cycle_end_date
  ) as validation_count,
  na.category as nomination_area
FROM nomination_results nr
JOIN profiles p ON p.id = nr.nominee_id
LEFT JOIN nomination_areas na ON na.id = nr.nomination_area_id
ORDER BY 
  nr.created_at DESC,
  nr.nomination_count DESC,
  validation_count DESC
LIMIT 6;