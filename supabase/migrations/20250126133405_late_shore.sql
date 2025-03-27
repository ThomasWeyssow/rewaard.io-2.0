-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can upload files" ON storage.objects;
DROP POLICY IF EXISTS "Owners can update their files" ON storage.objects;
DROP POLICY IF EXISTS "Owners can delete their files" ON storage.objects;

-- Create new policies that only allow admins to manage files
CREATE POLICY "Admins can upload files"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'hero-program' AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  );

CREATE POLICY "Admins can update files"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'hero-program' AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  );

CREATE POLICY "Admins can delete files"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'hero-program' AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN profile_roles pr ON pr.profile_id = p.id
      JOIN roles r ON r.id = pr.role_id
      WHERE p.id = auth.uid() AND r.name = 'Admin'
    )
  );