/*
  # Add Recognition Feature Schema

  1. New Tables
    - `recognition_programs`
      - Program configuration set by admin
      - Stores points per user, dates, etc.
    
    - `recognition_points`
      - Tracks user point balances
      - Both distributable and earned points
    
    - `recognitions`
      - Individual recognition records
      - Stores messages, points, tags, etc.

  2. Security
    - Enable RLS on all tables
    - Add appropriate policies
*/

-- Create recognition_programs table
CREATE TABLE recognition_programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL,
  points_per_user integer NOT NULL CHECK (points_per_user >= 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE recognition_programs ENABLE ROW LEVEL SECURITY;

-- Create policies for recognition_programs
CREATE POLICY "Anyone can read recognition programs"
  ON recognition_programs FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can manage recognition programs"
  ON recognition_programs FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profile_roles pr
      JOIN roles r ON r.id = pr.role_id
      WHERE pr.profile_id = auth.uid()
      AND r.name = 'Admin'
    )
  );

-- Create recognition_points table
CREATE TABLE recognition_points (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  program_id uuid REFERENCES recognition_programs(id) ON DELETE CASCADE NOT NULL,
  distributable_points integer NOT NULL DEFAULT 0 CHECK (distributable_points >= 0),
  earned_points integer NOT NULL DEFAULT 0 CHECK (earned_points >= 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (profile_id, program_id)
);

-- Enable RLS
ALTER TABLE recognition_points ENABLE ROW LEVEL SECURITY;

-- Create policies for recognition_points
CREATE POLICY "Users can read their own points"
  ON recognition_points FOR SELECT
  TO authenticated
  USING (profile_id = auth.uid());

CREATE POLICY "Only system can modify points"
  ON recognition_points FOR ALL
  TO authenticated
  USING (false)
  WITH CHECK (false);

-- Create recognitions table
CREATE TABLE recognitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id uuid REFERENCES recognition_programs(id) ON DELETE CASCADE NOT NULL,
  sender_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  points integer NOT NULL DEFAULT 0 CHECK (points >= 0),
  message text NOT NULL,
  image_url text,
  tags text[] NOT NULL DEFAULT '{}',
  is_private boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE recognitions ENABLE ROW LEVEL SECURITY;

-- Create policies for recognitions
CREATE POLICY "Users can read public recognitions"
  ON recognitions FOR SELECT
  TO authenticated
  USING (
    NOT is_private OR 
    sender_id = auth.uid() OR 
    receiver_id = auth.uid()
  );

CREATE POLICY "Users can create recognitions"
  ON recognitions FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Must be sender
    sender_id = auth.uid() AND
    -- Program must be active
    EXISTS (
      SELECT 1 FROM recognition_programs rp
      WHERE rp.id = program_id
      AND CURRENT_TIMESTAMP BETWEEN rp.start_date AND rp.end_date
    ) AND
    -- Must have enough points
    (
      points = 0 OR
      points <= (
        SELECT distributable_points 
        FROM recognition_points
        WHERE profile_id = auth.uid()
        AND program_id = program_id
      )
    )
  );

-- Create function to handle recognition points transfer
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
$$ LANGUAGE plpgsql;

-- Create trigger for points transfer
CREATE TRIGGER handle_recognition_points_trigger
  AFTER INSERT ON recognitions
  FOR EACH ROW
  EXECUTE FUNCTION handle_recognition_points();

-- Create function to initialize user points when program starts
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
$$ LANGUAGE plpgsql;

-- Create trigger for points initialization
CREATE TRIGGER initialize_program_points_trigger
  AFTER INSERT ON recognition_programs
  FOR EACH ROW
  EXECUTE FUNCTION initialize_program_points();

-- Create function to reset points at program end
CREATE OR REPLACE FUNCTION check_and_reset_program_points()
RETURNS void AS $$
BEGIN
  -- Reset points for ended programs
  UPDATE recognition_points rp
  SET distributable_points = 0
  FROM recognition_programs rprg
  WHERE rp.program_id = rprg.id
  AND rprg.end_date < CURRENT_TIMESTAMP
  AND rp.distributable_points > 0;
END;
$$ LANGUAGE plpgsql;

-- Schedule cron job to run daily at midnight UTC
SELECT cron.schedule(
  'reset-recognition-points',
  '0 0 * * *',
  'SELECT check_and_reset_program_points()'
);