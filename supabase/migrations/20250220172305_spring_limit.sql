-- Drop existing storage policies
DO $$ 
BEGIN
  -- Drop profile-images policies
  DROP POLICY IF EXISTS "Public Access to profile images" ON storage.objects;
  DROP POLICY IF EXISTS "Users can upload their own profile image" ON storage.objects;
  DROP POLICY IF EXISTS "Users can update their own profile image" ON storage.objects;
  DROP POLICY IF EXISTS "Users can delete their own profile image" ON storage.objects;

  -- Drop hero-program policies
  DROP POLICY IF EXISTS "Public Access" ON storage.objects;
  DROP POLICY IF EXISTS "Admins can upload files" ON storage.objects;
  DROP POLICY IF EXISTS "Admins can update files" ON storage.objects;
  DROP POLICY IF EXISTS "Admins can delete files" ON storage.objects;
END $$;

-- Create new simplified policies for profile images
CREATE POLICY "profile_images_select"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'profile-images');

CREATE POLICY "profile_images_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'profile-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "profile_images_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'profile-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "profile_images_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'profile-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Create new simplified policies for hero banner
CREATE POLICY "hero_banner_select"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'hero-program');

CREATE POLICY "hero_banner_admin"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id = 'hero-program'
    AND EXISTS (
      SELECT 1 FROM auth.users u
      INNER JOIN profiles p ON p.id = u.id
      INNER JOIN profile_roles pr ON pr.profile_id = p.id
      INNER JOIN roles r ON r.id = pr.role_id
      WHERE u.id = auth.uid()
      AND r.name = 'Admin'
    )
  )
  WITH CHECK (
    bucket_id = 'hero-program'
    AND EXISTS (
      SELECT 1 FROM auth.users u
      INNER JOIN profiles p ON p.id = u.id
      INNER JOIN profile_roles pr ON pr.profile_id = p.id
      INNER JOIN roles r ON r.id = pr.role_id
      WHERE u.id = auth.uid()
      AND r.name = 'Admin'
    )
  );

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