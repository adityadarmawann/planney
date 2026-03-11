-- =============================================
-- MIGRATION: Correct Historical Timestamp Offset (Safe + Idempotent)
-- =============================================
-- Problem:
-- Older app versions wrote local Asia/Jakarta wall-clock times to TIMESTAMPTZ
-- columns without converting them to UTC first.
--
-- Example of the old bug in app code:
--   DateTime.now().toIso8601String()
--
-- For Jakarta users, values such as "2026-03-10T09:39:00" were interpreted by
-- PostgreSQL/Supabase as UTC. The stored instant became 7 hours too late.
--
-- Scope of correction:
-- - public.expense_plans.created_at
-- - public.expense_plans.updated_at
-- - public.expense_plans.completed_at
-- - public.paylater_bills.paid_at
--
-- Intentionally NOT included:
-- - public.transactions.created_at (server default NOW(), already correct)
--
-- Safety:
-- - Uses cutoff timestamp (only rows before fixed release)
-- - Logs every corrected row into public.timezone_fix_audit
-- - Idempotent for the same fix key (no double-shift)

BEGIN;

-- Tune these 2 values before running on production.
-- cutoff_wib: release time of app version that already contains timezone fixes.
-- fix_key: unique identifier so this script won't re-apply the same correction.
WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib,
    'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
SELECT * FROM params;

CREATE TABLE IF NOT EXISTS public.timezone_fix_audit (
  id BIGSERIAL PRIMARY KEY,
  fix_key TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  column_name TEXT NOT NULL,
  old_value TIMESTAMPTZ,
  new_value TIMESTAMPTZ,
  corrected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (fix_key, table_name, record_id, column_name)
);

-- PREVIEW COUNTS
WITH params AS (
  SELECT TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib
)
SELECT 'expense_plans.created_at' AS field, COUNT(*) AS affected_rows
FROM public.expense_plans p, params
WHERE p.created_at < params.cutoff_wib
UNION ALL
SELECT 'expense_plans.updated_at' AS field, COUNT(*) AS affected_rows
FROM public.expense_plans p, params
WHERE p.updated_at < params.cutoff_wib
UNION ALL
SELECT 'expense_plans.completed_at' AS field, COUNT(*) AS affected_rows
FROM public.expense_plans p, params
WHERE p.completed_at IS NOT NULL
  AND p.completed_at < params.cutoff_wib
UNION ALL
SELECT 'paylater_bills.paid_at' AS field, COUNT(*) AS affected_rows
FROM public.paylater_bills b, params
WHERE b.paid_at IS NOT NULL
  AND b.paid_at < params.cutoff_wib;

-- APPLY FIX + AUDIT (created_at)
WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib,
    'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
), candidates AS (
  SELECT p.id, p.created_at AS old_value, (p.created_at - INTERVAL '7 hours') AS new_value
  FROM public.expense_plans p, params
  WHERE p.created_at < params.cutoff_wib
    AND NOT EXISTS (
      SELECT 1
      FROM public.timezone_fix_audit a
      WHERE a.fix_key = params.fix_key
        AND a.table_name = 'expense_plans'
        AND a.column_name = 'created_at'
        AND a.record_id = p.id
    )
), updated AS (
  UPDATE public.expense_plans p
  SET created_at = c.new_value
  FROM candidates c
  WHERE p.id = c.id
  RETURNING p.id, c.old_value, c.new_value
)
INSERT INTO public.timezone_fix_audit
  (fix_key, table_name, record_id, column_name, old_value, new_value)
SELECT
  'tz_fix_20260311_jakarta_v2',
  'expense_plans',
  u.id,
  'created_at',
  u.old_value,
  u.new_value
FROM updated u;

-- APPLY FIX + AUDIT (updated_at)
WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib,
    'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
), candidates AS (
  SELECT p.id, p.updated_at AS old_value, (p.updated_at - INTERVAL '7 hours') AS new_value
  FROM public.expense_plans p, params
  WHERE p.updated_at < params.cutoff_wib
    AND NOT EXISTS (
      SELECT 1
      FROM public.timezone_fix_audit a
      WHERE a.fix_key = params.fix_key
        AND a.table_name = 'expense_plans'
        AND a.column_name = 'updated_at'
        AND a.record_id = p.id
    )
), updated AS (
  UPDATE public.expense_plans p
  SET updated_at = c.new_value
  FROM candidates c
  WHERE p.id = c.id
  RETURNING p.id, c.old_value, c.new_value
)
INSERT INTO public.timezone_fix_audit
  (fix_key, table_name, record_id, column_name, old_value, new_value)
SELECT
  'tz_fix_20260311_jakarta_v2',
  'expense_plans',
  u.id,
  'updated_at',
  u.old_value,
  u.new_value
FROM updated u;

-- APPLY FIX + AUDIT (completed_at)
WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib,
    'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
), candidates AS (
  SELECT p.id, p.completed_at AS old_value, (p.completed_at - INTERVAL '7 hours') AS new_value
  FROM public.expense_plans p, params
  WHERE p.completed_at IS NOT NULL
    AND p.completed_at < params.cutoff_wib
    AND NOT EXISTS (
      SELECT 1
      FROM public.timezone_fix_audit a
      WHERE a.fix_key = params.fix_key
        AND a.table_name = 'expense_plans'
        AND a.column_name = 'completed_at'
        AND a.record_id = p.id
    )
), updated AS (
  UPDATE public.expense_plans p
  SET completed_at = c.new_value
  FROM candidates c
  WHERE p.id = c.id
  RETURNING p.id, c.old_value, c.new_value
)
INSERT INTO public.timezone_fix_audit
  (fix_key, table_name, record_id, column_name, old_value, new_value)
SELECT
  'tz_fix_20260311_jakarta_v2',
  'expense_plans',
  u.id,
  'completed_at',
  u.old_value,
  u.new_value
FROM updated u;

-- APPLY FIX + AUDIT (paylater_bills.paid_at)
WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib,
    'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
), candidates AS (
  SELECT b.id, b.paid_at AS old_value, (b.paid_at - INTERVAL '7 hours') AS new_value
  FROM public.paylater_bills b, params
  WHERE b.paid_at IS NOT NULL
    AND b.paid_at < params.cutoff_wib
    AND NOT EXISTS (
      SELECT 1
      FROM public.timezone_fix_audit a
      WHERE a.fix_key = params.fix_key
        AND a.table_name = 'paylater_bills'
        AND a.column_name = 'paid_at'
        AND a.record_id = b.id
    )
), updated AS (
  UPDATE public.paylater_bills b
  SET paid_at = c.new_value
  FROM candidates c
  WHERE b.id = c.id
  RETURNING b.id, c.old_value, c.new_value
)
INSERT INTO public.timezone_fix_audit
  (fix_key, table_name, record_id, column_name, old_value, new_value)
SELECT
  'tz_fix_20260311_jakarta_v2',
  'paylater_bills',
  u.id,
  'paid_at',
  u.old_value,
  u.new_value
FROM updated u;

-- POST-CHECK SUMMARY
SELECT
  table_name,
  column_name,
  COUNT(*) AS corrected_rows,
  MIN(corrected_at) AS first_corrected_at,
  MAX(corrected_at) AS last_corrected_at
FROM public.timezone_fix_audit
WHERE fix_key = 'tz_fix_20260311_jakarta_v2'
GROUP BY table_name, column_name
ORDER BY table_name, column_name;

COMMIT;