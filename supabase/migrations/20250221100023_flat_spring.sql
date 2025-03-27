-- Add logo_url column to settings if it doesn't exist
ALTER TABLE settings
ADD COLUMN IF NOT EXISTS logo_url text;

-- Drop existing storage policies
DO $$ 
BEGIN
  -- Drop all existing policies for storage.objects
  DROP POLICY IF EXISTS "allow_storage_operations" ON storage.objects;
  DROP POLICY IF EXISTS "allow_public_read" ON storage.objects;
  DROP POLICY IF EXISTS "allow_all_storage" ON storage.objects;
END $$;

-- Create a single super simple policy that allows everything
CREATE POLICY "allow_all_storage"
  ON storage.objects FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- Verify the policies
SELECT 
  'Storage policies:' as section,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'storage'
ORDER BY tablename, policyname;