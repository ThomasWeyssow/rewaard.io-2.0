-- Create votes table if it doesn't exist
CREATE TABLE IF NOT EXISTS votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  voted_for_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  nomination_cycle_start date NOT NULL,
  nomination_cycle_end date NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(voter_id, nomination_cycle_start, nomination_cycle_end)
);

-- Enable RLS
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read all votes" ON votes;
DROP POLICY IF EXISTS "Users can create votes" ON votes;
DROP POLICY IF EXISTS "Users can delete their own votes" ON votes;

-- Create new policies
CREATE POLICY "Users can read all votes"
  ON votes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create votes"
  ON votes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = voter_id);

CREATE POLICY "Users can delete their own votes"
  ON votes FOR DELETE
  TO authenticated
  USING (auth.uid() = voter_id);

-- Add trigger for updating timestamps
CREATE TRIGGER update_votes_updated_at
  BEFORE UPDATE ON votes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();