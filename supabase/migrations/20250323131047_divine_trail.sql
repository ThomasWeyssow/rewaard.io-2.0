-- Drop the unique constraint on unlocked_rewards
ALTER TABLE unlocked_rewards
DROP CONSTRAINT IF EXISTS unlocked_rewards_user_id_reward_id_key;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read their own unlocked rewards" ON unlocked_rewards;
DROP POLICY IF EXISTS "Users can unlock rewards" ON unlocked_rewards;

-- Create new policies without unique constraint check
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

-- Log the changes
DO $$
BEGIN
  RAISE NOTICE 'Removed unique constraint from unlocked_rewards to allow multiple unlocks';
END $$;