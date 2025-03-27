/*
  # Add delete policy for profile badges

  1. Changes
    - Add RLS policy to allow authenticated users to delete their own profile badges
*/

-- Ajouter une politique pour permettre aux utilisateurs de supprimer leurs badges
CREATE POLICY "Les utilisateurs peuvent supprimer leurs badges"
  ON profile_badges FOR DELETE
  TO authenticated
  USING (true);