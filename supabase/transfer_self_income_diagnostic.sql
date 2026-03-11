-- =============================================
-- TRANSFER SELF-INCOME DIAGNOSTIC
-- =============================================
-- Tujuan:
-- 1) Deteksi transfer yang terlanjur mengarah ke diri sendiri
-- 2) Verifikasi pasangan transfer_out / transfer_in per ref_code
-- 3) Cek mismatch wallet transaksi vs wallet user

-- 0) Baseline: pastikan database ini memang punya data transaksi
SELECT
  COUNT(*) AS total_transactions,
  MIN(created_at) AS first_tx_at,
  MAX(created_at) AS last_tx_at
FROM public.transactions;

-- 0b) Distribusi tipe transaksi (akan selalu ada output walau 0 row pada anomali)
SELECT
  type,
  COUNT(*) AS total_rows
FROM public.transactions
GROUP BY type
ORDER BY total_rows DESC, type ASC;

-- 0c) 20 transaksi terakhir untuk sanity check environment/project
SELECT
  id,
  created_at,
  type,
  sender_id,
  receiver_id,
  wallet_id,
  amount,
  ref_code,
  note
FROM public.transactions
ORDER BY created_at DESC
LIMIT 20;

-- A) Self transfer rows (harusnya 0)
SELECT
  id,
  created_at,
  type,
  sender_id,
  receiver_id,
  wallet_id,
  amount,
  ref_code,
  note
FROM public.transactions
WHERE type IN ('transfer_out', 'transfer_in')
  AND sender_id IS NOT NULL
  AND receiver_id IS NOT NULL
  AND sender_id = receiver_id
ORDER BY created_at DESC;

-- B) Ringkasan jumlah self transfer per hari
SELECT
  (created_at AT TIME ZONE 'Asia/Jakarta')::date AS day_wib,
  COUNT(*) AS self_transfer_rows
FROM public.transactions
WHERE type IN ('transfer_out', 'transfer_in')
  AND sender_id IS NOT NULL
  AND receiver_id IS NOT NULL
  AND sender_id = receiver_id
GROUP BY 1
ORDER BY 1 DESC;

-- C) Pasangan transfer yang tidak lengkap per base_ref_code
WITH normalized AS (
  SELECT
    id,
    type,
    sender_id,
    receiver_id,
    wallet_id,
    amount,
    created_at,
    CASE
      WHEN type = 'transfer_in' AND right(ref_code, 2) = 'IN' THEN left(ref_code, length(ref_code) - 2)
      ELSE ref_code
    END AS base_ref_code
  FROM public.transactions
  WHERE type IN ('transfer_out', 'transfer_in')
), grouped AS (
  SELECT
    base_ref_code,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE type = 'transfer_out') AS out_rows,
    COUNT(*) FILTER (WHERE type = 'transfer_in') AS in_rows,
    MIN(created_at) AS first_seen,
    MAX(created_at) AS last_seen
  FROM normalized
  GROUP BY base_ref_code
)
SELECT *
FROM grouped
WHERE out_rows <> 1 OR in_rows <> 1
ORDER BY last_seen DESC;

-- D) Cek wallet ownership mismatch di transaksi transfer
SELECT
  t.id,
  t.created_at,
  t.type,
  t.sender_id,
  t.receiver_id,
  t.wallet_id,
  w.user_id AS wallet_owner_user_id,
  t.ref_code
FROM public.transactions t
JOIN public.wallets w ON w.id = t.wallet_id
WHERE t.type IN ('transfer_out', 'transfer_in')
  AND (
    (t.type = 'transfer_out' AND w.user_id <> t.sender_id)
    OR
    (t.type = 'transfer_in' AND w.user_id <> t.receiver_id)
  )
ORDER BY t.created_at DESC;

-- E) Broad check: semua tipe yang diawali 'transfer' (termasuk tipe baru)
SELECT
  id,
  created_at,
  type,
  sender_id,
  receiver_id,
  wallet_id,
  amount,
  ref_code,
  note
FROM public.transactions
WHERE type::text LIKE 'transfer%'
ORDER BY created_at DESC;
