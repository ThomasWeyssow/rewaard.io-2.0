/*
  # Create cycle_winner table

  1. New Tables
    - `cycle_winner`
      - `id` (uuid, primary key)
      - `cycle_id` (uuid, foreign key to nomination_cycles)
      - `nominee_id` (uuid, foreign key to profiles)
      - `created_at` (timestamp with timezone)

  2. Foreign Keys
    - Links cycle_id to nomination_cycles table
    - Links nominee_id to profiles table

  3. Security
    - Enable RLS
    - Add policy for authenticated users to read winners
*/

-- Create the cycle_winner table
CREATE TABLE IF NOT EXISTS cycle_winner (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id uuid NOT NULL REFERENCES nomination_cycles(id) ON DELETE CASCADE,
  nominee_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_cycle_winner_cycle_id ON cycle_winner(cycle_id);
CREATE INDEX IF NOT EXISTS idx_cycle_winner_nominee_id ON cycle_winner(nominee_id);

-- Enable Row Level Security
ALTER TABLE cycle_winner ENABLE ROW LEVEL SECURITY;

-- Add policy for reading winners
CREATE POLICY "Anyone can read cycle winners" ON cycle_winner
  FOR SELECT
  TO authenticated
  USING (true);

-- Add policy for inserting winners (admin only)
CREATE POLICY "Only admins can insert winners" ON cycle_winner
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Add policy for deleting winners (admin only)
CREATE POLICY "Only admins can delete winners" ON cycle_winner
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Add unique constraint to ensure only one winner per cycle
ALTER TABLE cycle_winner ADD CONSTRAINT unique_cycle_winner UNIQUE (cycle_id);