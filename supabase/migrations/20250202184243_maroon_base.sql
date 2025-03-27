-- Afficher l'état actuel des cycles avec les dates formatées
SELECT 
  to_char(next_nomination_start_date, 'YYYY-MM-DD HH24:MI:SS') as next_start,
  to_char(next_nomination_end_date, 'YYYY-MM-DD HH24:MI:SS') as next_end,
  to_char(ongoing_nomination_start_date, 'YYYY-MM-DD HH24:MI:SS') as ongoing_start,
  to_char(ongoing_nomination_end_date, 'YYYY-MM-DD HH24:MI:SS') as ongoing_end,
  next_nomination_period,
  ongoing_nomination_period,
  next_nomination_area_id,
  ongoing_nomination_area_id
FROM settings;

-- Vérifier la condition de transition
SELECT 
  next_nomination_start_date <= CURRENT_TIMESTAMP as should_transition,
  CURRENT_TIMESTAMP as current_time,
  ongoing_nomination_start_date IS NULL as no_ongoing_cycle
FROM settings;