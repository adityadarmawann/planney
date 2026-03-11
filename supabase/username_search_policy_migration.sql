-- =============================================
-- USERNAME SEARCH POLICY MIGRATION
-- =============================================
-- Tujuan:
-- Mengizinkan user yang sudah login untuk mencari user lain berdasarkan username
-- (dibutuhkan fitur transfer ke pengguna).

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'users'
      AND policyname = 'Users can search users for transfer'
  ) THEN
    CREATE POLICY "Users can search users for transfer"
      ON public.users
      FOR SELECT
      USING (auth.role() = 'authenticated');
  END IF;
END
$$;
