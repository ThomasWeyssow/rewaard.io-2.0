-- Drop existing storage policies
DO $$ 
BEGIN
  -- Drop all existing policies for storage.objects
  DROP POLICY IF EXISTS "storage_select" ON storage.objects;
  DROP POLICY IF EXISTS "storage_insert" ON storage.objects;
  DROP POLICY IF EXISTS "storage_update" ON storage.objects;
  DROP POLICY IF EXISTS "storage_delete" ON storage.objects;
END $$;

-- Create a single super simple policy that allows all operations
CREATE POLICY "allow_storage_operations"
  ON storage.objects FOR ALL
  TO authenticated
  USING (bucket_id IN ('profile-images', 'hero-program'))
  WITH CHECK (bucket_id IN ('profile-images', 'hero-program'));

-- Create a separate policy for public read access
CREATE POLICY "allow_public_read"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id IN ('profile-images', 'hero-program'));

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