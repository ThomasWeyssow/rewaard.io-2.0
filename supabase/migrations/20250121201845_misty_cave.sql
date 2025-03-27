/*
  # Fix profile_badges RLS policy

  1. Changes
    - Remove the admin-only restriction for inserting badges
    - Allow authenticated users to add badges to any profile
    - Keep the existing select policy unchanged

  2. Security
    - Enable RLS on profile_badges table
    - Add policy for authenticated users to insert badges
*/

-- Supprimer l'ancienne politique d'insertion
DROP POLICY IF EXISTS "Seuls les admins peuvent attribuer des badges" ON profile_badges;

-- Créer une nouvelle politique permettant aux utilisateurs authentifiés d'attribuer des badges
CREATE POLICY "Les utilisateurs authentifiés peuvent attribuer des badges"
  ON profile_badges FOR INSERT
  TO authenticated
  WITH CHECK (true);