/*
  # Add User Roles Support

  1. New Tables
    - `roles` - Stores available user roles
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `created_at` (timestamp)
    - `profile_roles` - Junction table for user-role relationships
      - `profile_id` (uuid, references profiles)
      - `role_id` (uuid, references roles)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on both tables
    - Add policies for reading roles
    - Add policies for managing profile roles

  3. Initial Data
    - Insert default roles (User, ExCom, Admin)
    - Assign 'User' role to all existing profiles
*/

-- Create roles table
CREATE TABLE roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create profile_roles junction table
CREATE TABLE profile_roles (
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  role_id uuid REFERENCES roles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (profile_id, role_id)
);

-- Enable RLS
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_roles ENABLE ROW LEVEL SECURITY;

-- Policies for roles table
CREATE POLICY "Anyone can read roles"
  ON roles FOR SELECT
  TO authenticated
  USING (true);

-- Policies for profile_roles table
CREATE POLICY "Anyone can read profile roles"
  ON profile_roles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can manage profile roles"
  ON profile_roles FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Insert default roles
INSERT INTO roles (name) VALUES
  ('User'),
  ('ExCom'),
  ('Admin');

-- Assign 'User' role to all existing profiles
INSERT INTO profile_roles (profile_id, role_id)
SELECT 
  profiles.id,
  roles.id
FROM profiles
CROSS JOIN roles
WHERE roles.name = 'User'
ON CONFLICT DO NOTHING;

-- Create index for better performance
CREATE INDEX idx_profile_roles_profile_id ON profile_roles(profile_id);
CREATE INDEX idx_profile_roles_role_id ON profile_roles(role_id);