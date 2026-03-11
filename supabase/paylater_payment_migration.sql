-- =============================================
-- PAYLATER PAYMENT METHOD MIGRATION
-- Mengubah PayLater dari pencairan dana menjadi metode pembayaran
-- =============================================

-- 1. Tambah transaction types baru untuk pembayaran dengan PayLater
ALTER TYPE transaction_type ADD VALUE IF NOT EXISTS 'qris_paylater';
ALTER TYPE transaction_type ADD VALUE IF NOT EXISTS 'transfer_paylater';

-- 1a. Tambah kolom untuk sistem auto-increase limit
ALTER TABLE public.paylater_accounts
ADD COLUMN IF NOT EXISTS on_time_payment_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_paid_bills INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS late_payment_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_limit_increase TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS next_limit_review_date TIMESTAMP WITH TIME ZONE;

-- 1b. Update existing accounts: set initial limit 2.5jt & init tracking columns
UPDATE public.paylater_accounts 
SET 
  credit_limit = 2500000,  -- Limit awal 2.5jt (bisa naik sampai 10jt)
  on_time_payment_count = 0,
  total_paid_bills = 0,
  late_payment_count = 0,
  last_limit_increase = created_at,
  next_limit_review_date = created_at + INTERVAL '30 days'
WHERE on_time_payment_count IS NULL;

-- 2. Tambah kolom payment_type di paylater_bills untuk membedakan jenis pembayaran
ALTER TABLE public.paylater_bills
ADD COLUMN IF NOT EXISTS payment_type VARCHAR(20) DEFAULT 'disbursement' CHECK (payment_type IN ('disbursement', 'qris', 'transfer'));

-- 3. Tambah kolom merchant_info untuk menyimpan info merchant (jika QRIS)
ALTER TABLE public.paylater_bills
ADD COLUMN IF NOT EXISTS merchant_info JSONB;

-- 4. Tambah kolom recipient_info untuk menyimpan info penerima (jika transfer)
ALTER TABLE public.paylater_bills
ADD COLUMN IF NOT EXISTS recipient_info JSONB;

-- 5. Update comment untuk dokumentasi
COMMENT ON COLUMN public.paylater_bills.payment_type IS 'Jenis pembayaran: disbursement (cairkan ke wallet), qris (bayar merchant QRIS), transfer (transfer ke user)';
COMMENT ON COLUMN public.paylater_bills.merchant_info IS 'Info merchant untuk payment_type=qris: {merchant_name, merchant_city, ...}';
COMMENT ON COLUMN public.paylater_bills.recipient_info IS 'Info penerima untuk payment_type=transfer: {user_id, username, full_name}';

-- 6. Function untuk check overdue bills (bisa dipanggil via cron)
CREATE OR REPLACE FUNCTION check_overdue_paylater_bills()
RETURNS void AS $$
BEGIN
  UPDATE public.paylater_bills
  SET status = 'overdue'
  WHERE status = 'active'
    AND due_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- 7. Function untuk auto-increase credit limit based on payment behavior
CREATE OR REPLACE FUNCTION increase_paylater_limit_on_payment()
RETURNS TRIGGER AS $$
DECLARE
  v_account RECORD;
  v_was_on_time BOOLEAN;
  v_new_limit NUMERIC;
  v_can_increase BOOLEAN;
BEGIN
  -- Hanya proses jika bill baru dibayar (status berubah menjadi 'paid')
  IF NEW.status = 'paid' AND OLD.status != 'paid' THEN
    
    -- Ambil data akun PayLater
    SELECT * INTO v_account 
    FROM public.paylater_accounts 
    WHERE user_id = NEW.user_id;
    
    -- Cek apakah pembayaran tepat waktu (paid_at <= due_date)
    v_was_on_time := (NEW.paid_at <= NEW.due_date);
    
    -- Update payment tracking counters
    IF v_was_on_time THEN
      -- Pembayaran tepat waktu: increment on_time_payment_count
      UPDATE public.paylater_accounts
      SET 
        on_time_payment_count = on_time_payment_count + 1,
        total_paid_bills = total_paid_bills + 1,
        updated_at = CURRENT_TIMESTAMP
      WHERE user_id = NEW.user_id;
    ELSE
      -- Pembayaran terlambat: reset on_time counter, increment late counter
      UPDATE public.paylater_accounts
      SET 
        on_time_payment_count = 0,  -- Reset counter sebagai penalti
        total_paid_bills = total_paid_bills + 1,
        late_payment_count = late_payment_count + 1,
        updated_at = CURRENT_TIMESTAMP
      WHERE user_id = NEW.user_id;
    END IF;
    
    -- Reload account data setelah update counters
    SELECT * INTO v_account 
    FROM public.paylater_accounts 
    WHERE user_id = NEW.user_id;
    
    -- Cek eligibilitas untuk kenaikan limit
    v_can_increase := (
      v_account.on_time_payment_count >= 3  -- Minimal 3x bayar tepat waktu berturut-turut
      AND v_account.credit_limit < 10000000  -- Belum mencapai limit maksimal Rp 10jt
      AND v_account.status = 'active'  -- Akun aktif
      AND (
        v_account.last_limit_increase IS NULL 
        OR v_account.last_limit_increase + INTERVAL '30 days' <= CURRENT_TIMESTAMP
      )  -- Sudah lewat 30 hari sejak kenaikan terakhir
    );
    
    -- Proses kenaikan limit jika eligible
    IF v_can_increase THEN
      -- Naikkan Rp 500k, maksimal sampai Rp 10jt
      v_new_limit := LEAST(v_account.credit_limit + 500000, 10000000);
      
      UPDATE public.paylater_accounts
      SET 
        credit_limit = v_new_limit,
        on_time_payment_count = 0,  -- Reset counter setelah naik
        last_limit_increase = CURRENT_TIMESTAMP,
        next_limit_review_date = CURRENT_TIMESTAMP + INTERVAL '30 days',
        updated_at = CURRENT_TIMESTAMP
      WHERE user_id = NEW.user_id;
      
      -- Log kenaikan limit (muncul di Supabase logs)
      RAISE NOTICE 'PayLater limit increased for user % from Rp % to Rp %', 
        NEW.user_id, v_account.credit_limit, v_new_limit;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger untuk otomatis jalankan fungsi saat bill dibayar
DROP TRIGGER IF EXISTS trigger_increase_limit_on_payment ON public.paylater_bills;
CREATE TRIGGER trigger_increase_limit_on_payment
  AFTER UPDATE ON public.paylater_bills
  FOR EACH ROW
  EXECUTE FUNCTION increase_paylater_limit_on_payment();

-- 7. Comment untuk dokumentasi alur baru
COMMENT ON TABLE public.paylater_bills IS 
'Tagihan PayLater: 
- payment_type=disbursement: pencairan dana tunai ke wallet (cara lama)
- payment_type=qris: pembayaran QRIS merchant dengan PayLater
- payment_type=transfer: transfer ke user lain dengan PayLater';

-- 9. Comment untuk dokumentasi sistem auto-increase limit
COMMENT ON COLUMN public.paylater_accounts.on_time_payment_count IS 'Jumlah pembayaran tepat waktu berturut-turut (reset jika telat)';
COMMENT ON COLUMN public.paylater_accounts.total_paid_bills IS 'Total tagihan yang sudah dibayar (tidak reset)';
COMMENT ON COLUMN public.paylater_accounts.late_payment_count IS 'Jumlah pembayaran terlambat (akumulatif)';
COMMENT ON COLUMN public.paylater_accounts.last_limit_increase IS 'Timestamp kenaikan limit terakhir';
COMMENT ON COLUMN public.paylater_accounts.next_limit_review_date IS 'Tanggal berikutnya eligible untuk review kenaikan limit';

-- =============================================
-- SISTEM AUTO-INCREASE LIMIT PAYLATER
-- =============================================
-- Limit Awal: Rp 2.500.000
-- Kenaikan: Rp 500.000 per milestone
-- Maksimal: Rp 10.000.000
--
-- Rules:
-- 1. User harus bayar 3x tepat waktu berturut-turut
-- 2. Minimal jeda 30 hari antar kenaikan limit
-- 3. Reset counter jika ada pembayaran terlambat
-- 4. Otomatis trigger saat bayar tagihan
--
-- Contoh Progression:
-- - Awal: Rp 2.500.000
-- - 3x bayar tepat waktu → Rp 3.000.000
-- - 3x bayar tepat waktu lagi → Rp 3.500.000
-- - ... (dst sampai Rp 10.000.000)
-- =============================================

