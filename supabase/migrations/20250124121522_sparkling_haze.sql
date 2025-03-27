/*
  # Add nomination details and results tables

  1. New Tables
    - `nominations`
      - Stores nomination details including selected areas, justification, and remarks
      - Links to voter and nominee
      - Tracks nomination cycle dates
    - `nomination_results`
      - Stores final results for each nomination cycle
      - Includes winner information and statistics

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users
*/

-- Create nominations table
CREATE TABLE nominations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  nominee_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  selected_areas text[] NOT NULL,
  justification text NOT NULL,
  remarks text,
  nomination_cycle_start date NOT NULL,
  nomination_cycle_end date NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create nomination_results table
CREATE TABLE nomination_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  winner_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  cycle_start_date date NOT NULL,
  cycle_end_date date NOT NULL,
  total_votes integer NOT NULL DEFAULT 0,
  nomination_area_id uuid REFERENCES nomination_areas(id) ON DELETE SET NULL,
  nomination_area_category text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE nominations ENABLE ROW LEVEL SECURITY;
ALTER TABLE nomination_results ENABLE ROW LEVEL SECURITY;

-- Policies for nominations
CREATE POLICY "Users can read all nominations"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create nominations"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = voter_id);

-- Policies for nomination_results
CREATE POLICY "Users can read nomination results"
  ON nomination_results FOR SELECT
  TO authenticated
  USING (true);

-- Trigger for updating timestamps
CREATE TRIGGER update_nominations_updated_at
  BEFORE UPDATE ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();