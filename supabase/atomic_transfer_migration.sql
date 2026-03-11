-- Migration: Create atomic transfer RPC function
-- Purpose: Enable cross-user wallet transfers by bypassing RLS for balance operations
-- Created: 2026-03-05

-- Drop existing function if any
DROP FUNCTION IF EXISTS public.execute_wallet_transfer(uuid, uuid, numeric, numeric);

-- Create atomic transfer function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.execute_wallet_transfer(
  sender_user_id uuid,
  receiver_user_id uuid,
  transfer_amount numeric,
  transfer_fee numeric DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  sender_wallet_id uuid;
  sender_balance numeric;
  receiver_wallet_id uuid;
  total_deduct numeric;
BEGIN
  -- Verify caller is authenticated
  IF auth.role() <> 'authenticated' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Verify caller is the sender
  IF auth.uid() <> sender_user_id THEN
    RAISE EXCEPTION 'You can only transfer from your own wallet';
  END IF;

  -- Prevent self transfer at database level.
  IF sender_user_id = receiver_user_id THEN
    RAISE EXCEPTION 'Cannot transfer to self';
  END IF;

  -- Basic input validation
  IF transfer_amount IS NULL OR transfer_amount <= 0 THEN
    RAISE EXCEPTION 'Transfer amount must be greater than zero';
  END IF;

  IF transfer_fee IS NULL OR transfer_fee < 0 THEN
    RAISE EXCEPTION 'Transfer fee cannot be negative';
  END IF;

  -- Calculate total deduction
  total_deduct := transfer_amount + transfer_fee;

  -- Get and lock sender wallet
  SELECT id, balance INTO sender_wallet_id, sender_balance
  FROM wallets
  WHERE user_id = sender_user_id AND is_active = true
  FOR UPDATE;

  IF sender_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Sender wallet not found';
  END IF;

  -- Check sufficient balance
  IF sender_balance < total_deduct THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  -- Get and lock receiver wallet
  SELECT id INTO receiver_wallet_id
  FROM wallets
  WHERE user_id = receiver_user_id AND is_active = true
  FOR UPDATE;

  IF receiver_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Receiver wallet not found';
  END IF;

  IF sender_wallet_id = receiver_wallet_id THEN
    RAISE EXCEPTION 'Receiver wallet must be different from sender wallet';
  END IF;

  -- Deduct from sender
  UPDATE wallets
  SET balance = balance - total_deduct,
      updated_at = now()
  WHERE id = sender_wallet_id;

  -- Add to receiver
  UPDATE wallets
  SET balance = balance + transfer_amount,
      updated_at = now()
  WHERE id = receiver_wallet_id;

  -- Return wallet IDs for transaction recording
  RETURN jsonb_build_object(
    'sender_wallet_id', sender_wallet_id,
    'receiver_wallet_id', receiver_wallet_id,
    'success', true
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.execute_wallet_transfer(uuid, uuid, numeric, numeric) TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION public.execute_wallet_transfer IS 'Atomically transfers balance between two user wallets, bypassing RLS for receiver wallet access. Only allows sender to initiate transfer from their own wallet.';
