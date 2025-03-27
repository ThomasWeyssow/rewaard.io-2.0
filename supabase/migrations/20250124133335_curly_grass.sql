/*
  # Suppression de la nomination d'Emma Laurent
  
  1. Suppression
    - Supprime la nomination d'Emma Laurent de la table nominations
*/

DELETE FROM nominations
WHERE nominee_id IN (
  SELECT id 
  FROM profiles 
  WHERE email = 'emma.laurent@company.com'
);