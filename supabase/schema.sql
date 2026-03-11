-- =============================================
-- PLANNEY DATABASE SCHEMA
-- =============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  phone VARCHAR(15),
  avatar_url TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  balance DECIMAL(15,2) DEFAULT 0.00 CHECK (balance >= 0),
  currency VARCHAR(3) DEFAULT 'IDR',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TYPE category_type AS ENUM ('income', 'expense');

CREATE TABLE public.categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  name VARCHAR(50) NOT NULL,
  icon VARCHAR(10) NOT NULL,
  color VARCHAR(7) NOT NULL,
  type category_type NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TYPE transaction_type AS ENUM (
  'topup', 'transfer_in', 'transfer_out',
  'bank_transfer', 'paylater_disbursement',
  'paylater_payment', 'withdrawal'
);

CREATE TYPE transaction_status AS ENUM ('pending', 'success', 'failed', 'cancelled');

CREATE TABLE public.transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID REFERENCES public.users(id),
  receiver_id UUID REFERENCES public.users(id),
  wallet_id UUID NOT NULL REFERENCES public.wallets(id),
  type transaction_type NOT NULL,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  fee DECIMAL(15,2) DEFAULT 0.00,
  status transaction_status DEFAULT 'success',
  note TEXT,
  ref_code VARCHAR(20) UNIQUE NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TYPE paylater_status AS ENUM ('active', 'suspended', 'closed');

CREATE TABLE public.paylater_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  credit_limit DECIMAL(15,2) DEFAULT 1000000.00,
  used_limit DECIMAL(15,2) DEFAULT 0.00,
  interest_rate DECIMAL(5,2) DEFAULT 2.50,
  status paylater_status DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TYPE bill_status AS ENUM ('active', 'paid', 'overdue', 'cancelled');

CREATE TABLE public.paylater_bills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  paylater_id UUID NOT NULL REFERENCES public.paylater_accounts(id),
  user_id UUID NOT NULL REFERENCES public.users(id),
  principal_amount DECIMAL(15,2) NOT NULL,
  interest_amount DECIMAL(15,2) NOT NULL,
  late_fee_amount DECIMAL(15,2) DEFAULT 0.00,
  total_due DECIMAL(15,2) NOT NULL,
  tenor_months INTEGER NOT NULL CHECK (tenor_months BETWEEN 1 AND 12),
  due_date DATE NOT NULL,
  paid_at TIMESTAMPTZ,
  status bill_status DEFAULT 'active',
  transaction_id UUID REFERENCES public.transactions(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TYPE period_type AS ENUM ('weekly', 'monthly', 'custom');

CREATE TABLE public.budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  period_type period_type NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_income DECIMAL(15,2) DEFAULT 0.00,
  total_expense DECIMAL(15,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TYPE item_type AS ENUM ('income', 'expense');

CREATE TABLE public.budget_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  budget_id UUID NOT NULL REFERENCES public.budgets(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.categories(id),
  user_id UUID NOT NULL REFERENCES public.users(id),
  type item_type NOT NULL,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  description TEXT,
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- FUNCTIONS & TRIGGERS

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, username, full_name)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE((NEW.raw_user_meta_data->>'username'), split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'full_name'), '')
  );
  INSERT INTO public.wallets (user_id) VALUES (NEW.id);
  INSERT INTO public.paylater_accounts (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_wallets_updated_at BEFORE UPDATE ON public.wallets FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_paylater_updated_at BEFORE UPDATE ON public.paylater_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON public.budgets FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ROW LEVEL SECURITY (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paylater_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paylater_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can search users for transfer" ON public.users FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view own wallet" ON public.wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own wallet" ON public.wallets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users can insert transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = sender_id OR sender_id IS NULL);
CREATE POLICY "Users can view own paylater" ON public.paylater_accounts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own paylater" ON public.paylater_accounts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own paylater bills" ON public.paylater_bills FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert paylater bills" ON public.paylater_bills FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own paylater bills" ON public.paylater_bills FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own budgets" ON public.budgets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert budgets" ON public.budgets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own budgets" ON public.budgets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own budgets" ON public.budgets FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own budget items" ON public.budget_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert budget items" ON public.budget_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own budget items" ON public.budget_items FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users can view categories" ON public.categories FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id);

-- SEED DATA: Default Categories
INSERT INTO public.categories (name, icon, color, type, is_default) VALUES
  ('Beasiswa', '🎓', '#4CAF50', 'income', TRUE),
  ('Gaji/Freelance', '💼', '#2196F3', 'income', TRUE),
  ('Kiriman Ortu', '👨‍👩‍👧', '#9C27B0', 'income', TRUE),
  ('Lainnya', '💰', '#607D8B', 'income', TRUE),
  ('Makan & Minum', '🍜', '#FF5722', 'expense', TRUE),
  ('Transport', '🚌', '#FF9800', 'expense', TRUE),
  ('Belanja', '🛍️', '#E91E63', 'expense', TRUE),
  ('Pendidikan', '📚', '#3F51B5', 'expense', TRUE),
  ('Hiburan', '🎮', '#00BCD4', 'expense', TRUE),
  ('Kesehatan', '💊', '#F44336', 'expense', TRUE),
  ('Tagihan', '📄', '#795548', 'expense', TRUE),
  ('Lainnya', '💸', '#9E9E9E', 'expense', TRUE);

-- =============================================
-- EXPENSE PLANS TABLE (untuk perencanaan pengeluaran)
-- =============================================

CREATE TABLE public.expense_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  planned_date DATE NOT NULL,
  planned_time TIME WITHOUT TIME ZONE DEFAULT TIME '09:00:00',
  category VARCHAR(100) NOT NULL,
  payment_source VARCHAR(100) NOT NULL,
  reminder_type VARCHAR(20), -- 'h-1', 'h-3', 'custom', null
  custom_reminder_hours INTEGER,
  custom_reminder_minutes INTEGER CHECK (custom_reminder_minutes IS NULL OR custom_reminder_minutes > 0),
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk query yang sering digunakan
CREATE INDEX idx_expense_plans_user_date ON public.expense_plans(user_id, planned_date);
CREATE INDEX idx_expense_plans_user_completed ON public.expense_plans(user_id, is_completed);

-- Enable RLS
ALTER TABLE public.expense_plans ENABLE ROW LEVEL SECURITY;

-- RLS Policy: User hanya bisa lihat expense plans miliknya sendiri
CREATE POLICY "Users can view their own expense plans"
  ON public.expense_plans
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: User hanya bisa insert expense plans untuk dirinya sendiri
CREATE POLICY "Users can create their own expense plans"
  ON public.expense_plans
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: User hanya bisa update expense plans miliknya sendiri
CREATE POLICY "Users can update their own expense plans"
  ON public.expense_plans
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: User hanya bisa delete expense plans miliknya sendiri
CREATE POLICY "Users can delete their own expense plans"
  ON public.expense_plans
  FOR DELETE
  USING (auth.uid() = user_id);

