-- Enable RLS on rewards table if not already enabled
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies
DROP POLICY IF EXISTS "Tout le monde peut voir les récompenses" ON rewards;
DROP POLICY IF EXISTS "Users can read rewards" ON rewards;
DROP POLICY IF EXISTS "Admins can manage rewards" ON rewards;

-- Create new policies
CREATE POLICY "Users can read rewards"
  ON rewards FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage rewards"
  ON rewards FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Log the changes
DO $$
BEGIN
  RAISE NOTICE 'Added RLS policies for rewards table';
END $$;