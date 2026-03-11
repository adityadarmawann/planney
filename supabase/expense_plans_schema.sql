-- =============================================
-- EXPENSE PLANS TABLE (untuk perencanaan pengeluaran)
-- =============================================

CREATE TABLE public.expense_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  planned_date DATE NOT NULL,
  category VARCHAR(100) NOT NULL,
  payment_source VARCHAR(100) NOT NULL,
  reminder_type VARCHAR(20), -- 'h-1', 'h-3', 'custom', null
  custom_reminder_hours INTEGER,
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
