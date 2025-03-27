-- Drop existing policies
DROP POLICY IF EXISTS "Users can read their own points" ON recognition_points;
DROP POLICY IF EXISTS "Only system can modify points" ON recognition_points;

-- Create new policies for recognition_points
CREATE POLICY "recognition_points_select"
  ON recognition_points FOR SELECT
  TO authenticated
  USING (profile_id = auth.uid());

CREATE POLICY "recognition_points_insert"
  ON recognition_points FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow admins to create initial point records
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

CREATE POLICY "recognition_points_update"
  ON recognition_points FOR UPDATE
  TO authenticated
  USING (
    -- Allow admins to update points
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Update initialize_program_points function to handle RLS
CREATE OR REPLACE FUNCTION initialize_program_points()
RETURNS TRIGGER AS $$
DECLARE
  admin_role_id uuid;
BEGIN
  -- Get Admin role ID
  SELECT id INTO admin_role_id
  FROM roles
  WHERE name = 'Admin';

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

-- Log the changes
DO $$
BEGIN
  RAISE NOTICE 'Updated RLS policies for recognition_points table';
END $$;