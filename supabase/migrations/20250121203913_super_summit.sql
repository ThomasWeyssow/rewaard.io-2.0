/*
  # Ajout des employés du mois

  1. Nouvelles données
    - Ajout de Sarah Weyssow comme employée du mois de Mars 2024
    - Ajout de Lucas Moreau comme employé du mois de Février 2024
    - Ajout de Sophie Martin comme employée du mois de Janvier 2024

  2. Modifications
    - Insertion des votes correspondants
*/

-- Insérer les votes pour Mars 2024 (Sarah Weyssow)
INSERT INTO votes (voter_id, voted_for_id, month, year)
SELECT 
  p.id as voter_id,
  (SELECT id FROM profiles WHERE name = 'Sarah Weyssow' LIMIT 1) as voted_for_id,
  3 as month,
  2024 as year
FROM profiles p
LIMIT 18;

-- Insérer les votes pour Février 2024 (Lucas Moreau)
INSERT INTO votes (voter_id, voted_for_id, month, year)
SELECT 
  p.id as voter_id,
  (SELECT id FROM profiles WHERE name = 'Lucas Moreau' LIMIT 1) as voted_for_id,
  2 as month,
  2024 as year
FROM profiles p
LIMIT 14;

-- Insérer les votes pour Janvier 2024 (Sophie Martin)
INSERT INTO votes (voter_id, voted_for_id, month, year)
SELECT 
  p.id as voter_id,
  (SELECT id FROM profiles WHERE name = 'Sophie Martin' LIMIT 1) as voted_for_id,
  1 as month,
  2024 as year
FROM profiles p
LIMIT 15;