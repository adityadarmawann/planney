-- =============================================
-- EXPENSE PLAN TIME + REMINDER MINUTES MIGRATION
-- =============================================
-- Adds support for:
-- 1) planned_time (HH:MM) on expense_plans
-- 2) custom_reminder_minutes for custom reminder in HH:MM duration
--
-- Safe to run multiple times.

BEGIN;

ALTER TABLE public.expense_plans
  ADD COLUMN IF NOT EXISTS planned_time TIME WITHOUT TIME ZONE DEFAULT TIME '09:00:00';

ALTER TABLE public.expense_plans
  ADD COLUMN IF NOT EXISTS custom_reminder_minutes INTEGER;

-- Backfill minutes from legacy hour-based value when available.
UPDATE public.expense_plans
SET custom_reminder_minutes = custom_reminder_hours * 60
WHERE custom_reminder_minutes IS NULL
  AND custom_reminder_hours IS NOT NULL;

-- Guardrail for invalid values.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'expense_plans_custom_reminder_minutes_check'
  ) THEN
    ALTER TABLE public.expense_plans
      ADD CONSTRAINT expense_plans_custom_reminder_minutes_check
      CHECK (
        custom_reminder_minutes IS NULL
        OR custom_reminder_minutes > 0
      );
  END IF;
END $$;

COMMIT;
