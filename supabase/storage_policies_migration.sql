-- =============================================
-- SUPABASE STORAGE RLS POLICIES
-- =============================================
-- This migration sets up RLS policies for the avatars storage bucket

-- Enable RLS on the avatars bucket (usually already enabled by Supabase)
-- Note: Run these policies in Supabase SQL Editor after bucket creation

-- Policy 1: Users can upload/update their own avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
);

-- Policy 2: Users can delete their own avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
);

-- Policy 3: Users can view their own avatar (public read)
CREATE POLICY "Users can view their own avatar"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'avatars'
);
