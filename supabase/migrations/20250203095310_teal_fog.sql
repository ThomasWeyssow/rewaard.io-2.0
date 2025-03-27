-- Exécuter manuellement la fonction check_and_update_nomination_cycles
SELECT check_and_update_nomination_cycles();

-- Vérifier l'état après l'exécution
SELECT 
  to_char(next_nomination_start_date, 'YYYY-MM-DD') as next_start,
  to_char(next_nomination_end_date, 'YYYY-MM-DD') as next_end,
  to_char(ongoing_nomination_start_date, 'YYYY-MM-DD') as ongoing_start,
  to_char(ongoing_nomination_end_date, 'YYYY-MM-DD') as ongoing_end,
  next_nomination_period,
  ongoing_nomination_period,
  next_nomination_area_id,
  ongoing_nomination_area_id
FROM settings;