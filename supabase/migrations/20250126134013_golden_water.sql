-- Create profile-images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  5242880, -- 5MB in bytes
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Create policies for profile-images bucket
CREATE POLICY "Public Access to profile images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-images');

CREATE POLICY "Users can upload their own profile image"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'profile-images');

CREATE POLICY "Users can update their own profile image"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'profile-images' AND auth.uid() = owner);

CREATE POLICY "Users can delete their own profile image"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'profile-images' AND auth.uid() = owner);