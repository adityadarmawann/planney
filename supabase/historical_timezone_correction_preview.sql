-- =============================================
-- PREVIEW: Historical Timestamp Offset Correction
-- =============================================
-- Read-only helper script. No UPDATE executed.
--
-- Tune these 2 values:
-- 1) cutoff_wib: release time of app version that already contains timezone fix
-- 2) fix_key: must match migration file when you later execute correction

-- Ensure audit table exists so this preview can run before migration.
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

WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib,
    'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
SELECT * FROM params;

-- Total rows that are before cutoff
WITH params AS (
  SELECT TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib
)
SELECT 'expense_plans.created_at' AS field, COUNT(*) AS candidate_rows
FROM public.expense_plans p, params
WHERE p.created_at < params.cutoff_wib
UNION ALL
SELECT 'expense_plans.updated_at' AS field, COUNT(*) AS candidate_rows
FROM public.expense_plans p, params
WHERE p.updated_at < params.cutoff_wib
UNION ALL
SELECT 'expense_plans.completed_at' AS field, COUNT(*) AS candidate_rows
FROM public.expense_plans p, params
WHERE p.completed_at IS NOT NULL
  AND p.completed_at < params.cutoff_wib
UNION ALL
SELECT 'paylater_bills.paid_at' AS field, COUNT(*) AS candidate_rows
FROM public.paylater_bills b, params
WHERE b.paid_at IS NOT NULL
  AND b.paid_at < params.cutoff_wib;

-- If migration is re-run, these are rows that would still be newly corrected
-- (idempotent check using timezone_fix_audit)
WITH params AS (
  SELECT
    TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib,
    'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
SELECT 'expense_plans.created_at' AS field, COUNT(*) AS rows_not_yet_corrected
FROM public.expense_plans p, params
WHERE p.created_at < params.cutoff_wib
  AND NOT EXISTS (
    SELECT 1 FROM public.timezone_fix_audit a
    WHERE a.fix_key = params.fix_key
      AND a.table_name = 'expense_plans'
      AND a.column_name = 'created_at'
      AND a.record_id = p.id
  )
UNION ALL
SELECT 'expense_plans.updated_at' AS field, COUNT(*) AS rows_not_yet_corrected
FROM public.expense_plans p, params
WHERE p.updated_at < params.cutoff_wib
  AND NOT EXISTS (
    SELECT 1 FROM public.timezone_fix_audit a
    WHERE a.fix_key = params.fix_key
      AND a.table_name = 'expense_plans'
      AND a.column_name = 'updated_at'
      AND a.record_id = p.id
  )
UNION ALL
SELECT 'expense_plans.completed_at' AS field, COUNT(*) AS rows_not_yet_corrected
FROM public.expense_plans p, params
WHERE p.completed_at IS NOT NULL
  AND p.completed_at < params.cutoff_wib
  AND NOT EXISTS (
    SELECT 1 FROM public.timezone_fix_audit a
    WHERE a.fix_key = params.fix_key
      AND a.table_name = 'expense_plans'
      AND a.column_name = 'completed_at'
      AND a.record_id = p.id
  )
UNION ALL
SELECT 'paylater_bills.paid_at' AS field, COUNT(*) AS rows_not_yet_corrected
FROM public.paylater_bills b, params
WHERE b.paid_at IS NOT NULL
  AND b.paid_at < params.cutoff_wib
  AND NOT EXISTS (
    SELECT 1 FROM public.timezone_fix_audit a
    WHERE a.fix_key = params.fix_key
      AND a.table_name = 'paylater_bills'
      AND a.column_name = 'paid_at'
      AND a.record_id = b.id
  );

-- Sample of impacted rows (before vs after simulation)
WITH params AS (
  SELECT TIMESTAMPTZ '2026-03-11 23:59:59+07' AS cutoff_wib
)
SELECT
  p.id,
  p.created_at AS stored_utc,
  p.created_at AT TIME ZONE 'Asia/Jakarta' AS shown_in_jakarta_before,
  (p.created_at - INTERVAL '7 hours') AS corrected_utc,
  (p.created_at - INTERVAL '7 hours') AT TIME ZONE 'Asia/Jakarta' AS shown_in_jakarta_after
FROM public.expense_plans p, params
WHERE p.created_at < params.cutoff_wib
ORDER BY p.created_at DESC
LIMIT 20;
