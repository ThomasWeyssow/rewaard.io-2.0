/*
  # Add RLS policy for nomination results

  1. Security
    - Add policy to allow authenticated users to create nomination results
*/

-- Add policy to allow authenticated users to create nomination results
CREATE POLICY "Users can create nomination results"
  ON nomination_results FOR INSERT
  TO authenticated
  WITH CHECK (true);