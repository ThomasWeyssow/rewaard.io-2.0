-- Drop existing policies
DROP POLICY IF EXISTS "recognitions_select" ON recognitions;
DROP POLICY IF EXISTS "recognitions_insert" ON recognitions;
DROP POLICY IF EXISTS "Users can read public recognitions" ON recognitions;
DROP POLICY IF EXISTS "Users can create recognitions" ON recognitions;

-- Create super simple policies for recognitions
CREATE POLICY "allow_all_recognitions"
  ON recognitions FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Drop existing policies for recognition_points
DROP POLICY IF EXISTS "recognition_points_select" ON recognition_points;
DROP POLICY IF EXISTS "recognition_points_insert" ON recognition_points;
DROP POLICY IF EXISTS "recognition_points_update" ON recognition_points;
DROP POLICY IF EXISTS "Users can read their own points" ON recognition_points;
DROP POLICY IF EXISTS "Only system can modify points" ON recognition_points;

-- Create super simple policy for recognition_points
CREATE POLICY "allow_all_recognition_points"
  ON recognition_points FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Update initialize_program_points function to be SECURITY DEFINER
CREATE OR REPLACE FUNCTION initialize_program_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Create point records for all users
  INSERT INTO recognition_points (profile_id, program_id, distributable_points)
  SELECT 
    p.id as profile_id,
    NEW.id as program_id,
    NEW.points_per_user as distributable_points
  FROM profiles p;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update handle_recognition_points function to be SECURITY DEFINER
CREATE OR REPLACE FUNCTION handle_recognition_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Only handle points transfer if points > 0
  IF NEW.points > 0 THEN
    -- Deduct points from sender
    UPDATE recognition_points
    SET distributable_points = distributable_points - NEW.points
    WHERE profile_id = NEW.sender_id
    AND program_id = NEW.program_id;

    -- Add points to receiver
    UPDATE recognition_points
    SET earned_points = earned_points + NEW.points
    WHERE profile_id = NEW.receiver_id
    AND program_id = NEW.program_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log the changes
DO $$
BEGIN
  RAISE NOTICE 'Updated RLS policies for recognition system';
END $$;