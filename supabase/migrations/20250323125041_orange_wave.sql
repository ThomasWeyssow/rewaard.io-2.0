-- Create unlocked_rewards table
CREATE TABLE unlocked_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  reward_id uuid REFERENCES rewards(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, reward_id)
);

-- Enable RLS
ALTER TABLE unlocked_rewards ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read their own unlocked rewards"
  ON unlocked_rewards FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can unlock rewards"
  ON unlocked_rewards FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND
    EXISTS (
      SELECT 1 FROM recognition_points rp
      WHERE rp.profile_id = auth.uid()
      AND rp.earned_points >= (
        SELECT points_cost 
        FROM rewards 
        WHERE id = reward_id
      )
    )
  );

-- Create index for better performance
CREATE INDEX idx_unlocked_rewards_user 
ON unlocked_rewards(user_id);

-- Log the changes
DO $$
BEGIN
  RAISE NOTICE 'Created unlocked_rewards table with RLS policies';
END $$;