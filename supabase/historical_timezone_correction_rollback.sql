-- =============================================
-- ROLLBACK: Historical Timestamp Offset Correction
-- =============================================
-- This rollback restores old timestamp values from timezone_fix_audit.
--
-- IMPORTANT:
-- 1) Run only if you need to undo a specific fix_key.
-- 2) Replace fix_key below with the exact key used in migration.
-- 3) Safe to run multiple times (idempotent per current value check).

BEGIN;

-- Ensure audit table exists; if migration never ran, rollback becomes no-op.
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

-- Change this to the fix key you want to rollback
-- Example: 'tz_fix_20260311_jakarta_v2'
WITH params AS (
  SELECT 'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
SELECT * FROM params;

-- Preview rollback counts
WITH params AS (
  SELECT 'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
SELECT table_name, column_name, COUNT(*) AS rows_to_rollback
FROM public.timezone_fix_audit a, params
WHERE a.fix_key = params.fix_key
GROUP BY table_name, column_name
ORDER BY table_name, column_name;

-- Rollback expense_plans.created_at
WITH params AS (
  SELECT 'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
UPDATE public.expense_plans p
SET created_at = a.old_value
FROM public.timezone_fix_audit a, params
WHERE a.fix_key = params.fix_key
  AND a.table_name = 'expense_plans'
  AND a.column_name = 'created_at'
  AND a.record_id = p.id
  AND p.created_at = a.new_value;

-- Rollback expense_plans.updated_at
WITH params AS (
  SELECT 'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
UPDATE public.expense_plans p
SET updated_at = a.old_value
FROM public.timezone_fix_audit a, params
WHERE a.fix_key = params.fix_key
  AND a.table_name = 'expense_plans'
  AND a.column_name = 'updated_at'
  AND a.record_id = p.id
  AND p.updated_at = a.new_value;

-- Rollback expense_plans.completed_at
WITH params AS (
  SELECT 'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
UPDATE public.expense_plans p
SET completed_at = a.old_value
FROM public.timezone_fix_audit a, params
WHERE a.fix_key = params.fix_key
  AND a.table_name = 'expense_plans'
  AND a.column_name = 'completed_at'
  AND a.record_id = p.id
  AND p.completed_at = a.new_value;

-- Rollback paylater_bills.paid_at
WITH params AS (
  SELECT 'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
UPDATE public.paylater_bills b
SET paid_at = a.old_value
FROM public.timezone_fix_audit a, params
WHERE a.fix_key = params.fix_key
  AND a.table_name = 'paylater_bills'
  AND a.column_name = 'paid_at'
  AND a.record_id = b.id
  AND b.paid_at = a.new_value;

-- Post-check
WITH params AS (
  SELECT 'tz_fix_20260311_jakarta_v2'::TEXT AS fix_key
)
SELECT
  'expense_plans' AS table_name,
  'created_at' AS column_name,
  COUNT(*) AS rows_still_corrected
FROM public.expense_plans p
JOIN public.timezone_fix_audit a ON a.record_id = p.id
JOIN params ON TRUE
WHERE a.fix_key = params.fix_key
  AND a.table_name = 'expense_plans'
  AND a.column_name = 'created_at'
  AND p.created_at = a.new_value
UNION ALL
SELECT
  'expense_plans' AS table_name,
  'updated_at' AS column_name,
  COUNT(*) AS rows_still_corrected
FROM public.expense_plans p
JOIN public.timezone_fix_audit a ON a.record_id = p.id
JOIN params ON TRUE
WHERE a.fix_key = params.fix_key
  AND a.table_name = 'expense_plans'
  AND a.column_name = 'updated_at'
  AND p.updated_at = a.new_value
UNION ALL
SELECT
  'expense_plans' AS table_name,
  'completed_at' AS column_name,
  COUNT(*) AS rows_still_corrected
FROM public.expense_plans p
JOIN public.timezone_fix_audit a ON a.record_id = p.id
JOIN params ON TRUE
WHERE a.fix_key = params.fix_key
  AND a.table_name = 'expense_plans'
  AND a.column_name = 'completed_at'
  AND p.completed_at = a.new_value
UNION ALL
SELECT
  'paylater_bills' AS table_name,
  'paid_at' AS column_name,
  COUNT(*) AS rows_still_corrected
FROM public.paylater_bills b
JOIN public.timezone_fix_audit a ON a.record_id = b.id
JOIN params ON TRUE
WHERE a.fix_key = params.fix_key
  AND a.table_name = 'paylater_bills'
  AND a.column_name = 'paid_at'
  AND b.paid_at = a.new_value;

COMMIT;
