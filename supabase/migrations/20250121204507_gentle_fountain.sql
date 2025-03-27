/*
  # Ajout des votes pour les employés du mois

  1. Modifications
    - Suppression des anciens votes pour éviter les doublons
    - Ajout des votes pour Sarah Weyssow (Mars 2024)
    - Ajout des votes pour Lucas Moreau (Février 2024)
    - Ajout des votes pour Sophie Martin (Janvier 2024)
*/

-- Supprimer les anciens votes pour éviter les doublons
DELETE FROM votes 
WHERE (month = 1 OR month = 2 OR month = 3) 
AND year = 2024;

-- Insérer les votes pour Mars 2024 (Sarah Weyssow)
WITH sarah AS (
  SELECT id FROM profiles WHERE email = 'sarah.weyssow@company.com' LIMIT 1
)
INSERT INTO votes (voter_id, voted_for_id, month, year)
SELECT 
  p.id,
  (SELECT id FROM sarah),
  3,
  2024
FROM profiles p
WHERE EXISTS (SELECT 1 FROM sarah)
LIMIT 18;

-- Insérer les votes pour Février 2024 (Lucas Moreau)
WITH lucas AS (
  SELECT id FROM profiles WHERE name = 'Lucas Moreau' LIMIT 1
)
INSERT INTO votes (voter_id, voted_for_id, month, year)
SELECT 
  p.id,
  (SELECT id FROM lucas),
  2,
  2024
FROM profiles p
WHERE EXISTS (SELECT 1 FROM lucas)
LIMIT 14;

-- Insérer les votes pour Janvier 2024 (Sophie Martin)
WITH sophie AS (
  SELECT id FROM profiles WHERE name = 'Sophie Martin' LIMIT 1
)
INSERT INTO votes (voter_id, voted_for_id, month, year)
SELECT 
  p.id,
  (SELECT id FROM sophie),
  1,
  2024
FROM profiles p
WHERE EXISTS (SELECT 1 FROM sophie)
LIMIT 15;