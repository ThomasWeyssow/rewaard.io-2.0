-- Update the unlock_reward function to remove unique constraint check
CREATE OR REPLACE FUNCTION unlock_reward(
  p_user_id uuid,
  p_reward_id uuid,
  p_points_cost integer
)
RETURNS void AS $$
BEGIN
  -- Check if user has enough points
  IF NOT EXISTS (
    SELECT 1 FROM recognition_points
    WHERE profile_id = p_user_id
    AND earned_points >= p_points_cost
  ) THEN
    RAISE EXCEPTION 'Insufficient points';
  END IF;

  -- Deduct points
  UPDATE recognition_points
  SET earned_points = earned_points - p_points_cost
  WHERE profile_id = p_user_id;

  -- Create unlocked reward record
  INSERT INTO unlocked_rewards (user_id, reward_id)
  VALUES (p_user_id, p_reward_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log the changes
DO $$
BEGIN
  RAISE NOTICE 'Updated unlock_reward function to allow multiple unlocks';
END $$;