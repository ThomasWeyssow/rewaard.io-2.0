-- Drop existing storage policies
DO $$ 
BEGIN
  -- Drop all existing policies for storage.objects
  DROP POLICY IF EXISTS "profile_images_select" ON storage.objects;
  DROP POLICY IF EXISTS "profile_images_insert" ON storage.objects;
  DROP POLICY IF EXISTS "profile_images_update" ON storage.objects;
  DROP POLICY IF EXISTS "profile_images_delete" ON storage.objects;
  DROP POLICY IF EXISTS "hero_banner_select" ON storage.objects;
  DROP POLICY IF EXISTS "hero_banner_admin" ON storage.objects;
END $$;

-- Create super simple policies for all storage operations
CREATE POLICY "storage_select"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id IN ('profile-images', 'hero-program'));

CREATE POLICY "storage_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id IN ('profile-images', 'hero-program'));

CREATE POLICY "storage_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id IN ('profile-images', 'hero-program'));

CREATE POLICY "storage_delete"
  ON storage.objects FOR DELETE
  TO authenticated
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