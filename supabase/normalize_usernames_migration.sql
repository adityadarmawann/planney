-- =============================================
-- NORMALIZE USERNAMES TO LOWERCASE
-- =============================================
-- Migration untuk meng-lowercase semua username yang sudah ada
-- Agar konsisten dengan implementasi baru yang selalu menyimpan
-- username dalam lowercase

-- Update semua username menjadi lowercase
UPDATE public.users 
SET username = LOWER(username)
WHERE username != LOWER(username);

-- Buat index case-insensitive untuk performa username lookup
-- (optional, tapi recommended untuk query yang lebih cepat)
CREATE INDEX IF NOT EXISTS idx_users_username_lower 
ON public.users (LOWER(username));

-- Tambah check constraint untuk memastikan username selalu lowercase
-- (optional - enforce di application level sudah cukup)
-- ALTER TABLE public.users 
-- ADD CONSTRAINT username_lowercase_check 
-- CHECK (username = LOWER(username));
