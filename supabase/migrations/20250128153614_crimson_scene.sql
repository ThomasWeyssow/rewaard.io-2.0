-- Make client_id nullable
ALTER TABLE profiles
ALTER COLUMN client_id DROP NOT NULL;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_client_id 
ON profiles(client_id);

-- Log the operation
DO $$
BEGIN
  RAISE NOTICE 'Modified profiles table: client_id is now nullable';
END $$;