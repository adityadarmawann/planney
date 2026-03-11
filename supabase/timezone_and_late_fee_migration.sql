-- =============================================
-- MIGRATION: Add Late Fee to PayLater Bills & Timezone Fix
-- =============================================
-- This migration adds late fee support for overdue PayLater bills
-- and ensures proper timezone handling for all timestamps

-- 1. Add late_fee_amount column to paylater_bills
-- Run this if the column doesn't exist yet
ALTER TABLE public.paylater_bills
ADD COLUMN IF NOT EXISTS late_fee_amount DECIMAL(15,2) DEFAULT 0.00;

-- 2. Create function to calculate late fees (Shopee-style)
-- 0-7 days overdue: 0%
-- 8-14 days overdue: 2.5% of principal
-- 15-30 days overdue: 5% of principal
-- 30+ days overdue: 10% of principal
CREATE OR REPLACE FUNCTION calculate_late_fee(
  principal_amount DECIMAL,
  due_date DATE,
  status TEXT
)
RETURNS DECIMAL AS $$
DECLARE
  days_overdue INTEGER;
BEGIN
  -- If bill is paid, no late fee
  IF status = 'paid' THEN
    RETURN 0.00;
  END IF;

  -- Calculate days overdue
  days_overdue := CURRENT_DATE - due_date;

  -- If not overdue, return 0
  IF days_overdue < 0 THEN
    RETURN 0.00;
  END IF;

  -- Calculate late fee based on days overdue
  IF days_overdue <= 7 THEN
    RETURN 0.00;
  ELSIF days_overdue <= 14 THEN
    RETURN principal_amount * 0.025;
  ELSIF days_overdue <= 30 THEN
    RETURN principal_amount * 0.05;
  ELSE
    RETURN principal_amount * 0.10;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 3. Create function to auto-update status to 'overdue'
CREATE OR REPLACE FUNCTION update_overdue_bills()
RETURNS TABLE(id UUID, old_status TEXT, new_status TEXT) AS $$
BEGIN
  RETURN QUERY
  UPDATE public.paylater_bills
  SET status = 'overdue'
  WHERE status = 'active' 
    AND due_date < CURRENT_DATE
    AND CURRENT_DATE - due_date > 0
  RETURNING 
    public.paylater_bills.id,
    'active'::TEXT as old_status,
    'overdue'::TEXT as new_status;
END;
$$ LANGUAGE plpgsql;

-- 4. NOTE: Timezone handling for timestamps
-- Supabase stores all timestamps in UTC with timezone info (TIMESTAMPTZ)
-- When retrieving in Dart:
-- - Use DateTime.parse() which correctly handles timezone
-- - Use .toLocal() to convert UTC to local time for display
-- - Use .toUtc() to ensure UTC for storage

-- Example in Dart:
-- DateTime utcTime = DateTime.parse(json['created_at']);
-- DateTime localTime = utcTime.toLocal();  // Convert to user's local timezone

-- 5. Run this query periodically (via scheduled task or app startup) to update overdue bills:
-- SELECT update_overdue_bills();

-- Or create a scheduled job (Supabase Extension required):
-- Note: Currently requires manual execution or app-side calculation
-- The Flutter app already calculates this in PaylaterBillModel's effectiveStatus getter
