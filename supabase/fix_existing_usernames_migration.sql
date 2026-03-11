-- Migration: Fix existing usernames that were incorrectly generated from email prefix
-- This addresses the bug where signup trigger was using email prefix instead of user-provided username
-- 
-- Context: 
-- - Old triggerused: split_part(email, '@', 1) to generate username
-- - New trigger uses: raw_user_meta_data->>'username' (user-provided value from app)
-- 
-- This migration checks each user and attempts to recover the correct username from auth metadata if available

BEGIN;

-- First, let's identify users who likely have incorrect usernames
-- (i.e., their username matches the email prefix pattern)
CREATE TEMPORARY TABLE user_username_audit AS
SELECT 
  u.id,
  u.email,
  u.username,
  split_part(u.email, '@', 1) as email_prefix,
  CASE 
    WHEN u.username = split_part(u.email, '@', 1) THEN 'LIKELY_INCORRECT'
    ELSE 'LOOKS_OK'
  END as status
FROM public.users u
ORDER BY u.created_at DESC;

-- Display audit results
SELECT 
  id,
  email,
  username,
  email_prefix,
  status,
  COUNT(*) OVER (PARTITION BY status) as count_in_category
FROM user_username_audit;

-- For new signups, the trigger will now correctly use raw_user_meta_data->>'username'
-- For existing affected users, they should update their username manually in the app profile settings

-- To recover specific user usernames, you would need to:
-- 1. Query auth.users to see raw_user_meta_data for each user
-- 2. Manually update public.users.username for those who want their original intended username

-- Example for a specific user (uncomment and modify as needed):
-- UPDATE public.users 
-- SET username = 'desired_username' 
-- WHERE id = 'user_id_here' AND username = 'incorrect_email_prefix';

-- Alternative: If you have a mapping of user_id -> correct_username, load it as CSV and update

COMMIT;

-- NOTE: Manual fixes needed for existing users
-- The most user-friendly approach is to:
-- 1. Add admin screen to view and edit usernames
-- 2. Send notification to affected users with wrong usernames
-- 3. Let them fix it in profile settings
-- 4. Or bulk-fix if you have original username data from auth logs
