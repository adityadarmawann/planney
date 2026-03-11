-- =============================================
-- RECIPIENT WALLET LOOKUP MIGRATION
-- =============================================
-- Tujuan:
-- Menyediakan RPC aman untuk mengambil wallet_id penerima transfer
-- tanpa membuka akses SELECT semua data wallets via RLS.

CREATE OR REPLACE FUNCTION public.get_recipient_wallet_id(target_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  recipient_wallet_id uuid;
BEGIN
  IF auth.role() <> 'authenticated' THEN
    RETURN NULL;
  END IF;

  -- Sender cannot resolve their own wallet as transfer recipient.
  IF auth.uid() = target_user_id THEN
    RETURN NULL;
  END IF;

  SELECT w.id
  INTO recipient_wallet_id
  FROM public.wallets w
  WHERE w.user_id = target_user_id
    AND w.is_active = TRUE
  LIMIT 1;

  RETURN recipient_wallet_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_recipient_wallet_id(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_recipient_wallet_id(uuid) TO authenticated;
