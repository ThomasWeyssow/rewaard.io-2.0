-- Drop existing policies
DROP POLICY IF EXISTS "Users can read public recognitions" ON recognitions;
DROP POLICY IF EXISTS "Users can create recognitions" ON recognitions;

-- Create new policies for recognitions
CREATE POLICY "recognitions_select"
  ON recognitions FOR SELECT
  TO authenticated
  USING (
    NOT is_private OR 
    sender_id = auth.uid() OR 
    receiver_id = auth.uid()
  );

CREATE POLICY "recognitions_insert"
  ON recognitions FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Must be sender
    sender_id = auth.uid()
  );

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
  RAISE NOTICE 'Updated RLS policies for recognitions table';
END $$;