  -- ==========================================
  -- STORAGE SETUP: Avatars Bucket
  -- ==========================================

  -- 1. Create the bucket if it doesn't exist
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('avatars', 'avatars', true)
  ON CONFLICT (id) DO NOTHING;

  -- 2. Allow public access to read avatars
  CREATE POLICY "Public Access" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

  -- 3. Allow authenticated users to upload their own avatars
  CREATE POLICY "Authenticated users can upload avatars" ON storage.objects
    FOR INSERT WITH CHECK (
      bucket_id = 'avatars' AND 
      auth.role() = 'authenticated'
    );

  -- 4. Allow users to update or delete their own avatars
  CREATE POLICY "Users can update their own avatars" ON storage.objects
    FOR UPDATE WITH CHECK ( 
      bucket_id = 'avatars' AND 
      auth.uid()::text = (storage.foldername(name))[1]
    );
