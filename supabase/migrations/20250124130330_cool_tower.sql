-- Drop existing nominations table if it exists
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Users can read all nominations" ON nominations;
  DROP POLICY IF EXISTS "Users can create nominations" ON nominations;
  DROP POLICY IF EXISTS "Users can delete their own nominations" ON nominations;
  
  -- Drop existing trigger if it exists
  DROP TRIGGER IF EXISTS update_nominations_updated_at ON nominations;
  
  -- Drop the table if it exists
  DROP TABLE IF EXISTS nominations;
END $$;

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
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT nominations_voter_cycle_unique UNIQUE (voter_id, nomination_cycle_start, nomination_cycle_end)
);

-- Enable RLS
ALTER TABLE nominations ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read all nominations"
  ON nominations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create nominations"
  ON nominations FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = voter_id);

CREATE POLICY "Users can delete their own nominations"
  ON nominations FOR DELETE
  TO authenticated
  USING (auth.uid() = voter_id);

-- Add trigger for updating timestamps
CREATE TRIGGER update_nominations_updated_at
  BEFORE UPDATE ON nominations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();