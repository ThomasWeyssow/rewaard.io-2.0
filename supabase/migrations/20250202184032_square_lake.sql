-- Exécuter manuellement la fonction check_and_update_nomination_cycles
SELECT check_and_update_nomination_cycles();

-- Vérifier l'état après l'exécution
SELECT 
  next_nomination_start_date,
  next_nomination_end_date,
  next_nomination_area_id,
  next_nomination_period,
  ongoing_nomination_start_date,
  ongoing_nomination_end_date,
  ongoing_nomination_area_id,
  ongoing_nomination_period
FROM settings;