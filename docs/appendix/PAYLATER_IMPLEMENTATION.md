# PayLater Payment Method Implementation

## ✅ Completed

### 1. Database Schema (paylater_payment_migration.sql)
- Added new transaction types: `qris_paylater`, `transfer_paylater`
- Added `payment_type` column to paylater_bills ('disbursement', 'qris', 'transfer')
- Added `merchant_info` and `recipient_info` JSONB columns
- Created `check_overdue_paylater_bills()` function
- **NEW**: Auto-increase limit system:
  - Added tracking columns: `on_time_payment_count`, `total_paid_bills`, `late_payment_count`
  - Added `last_limit_increase`, `next_limit_review_date` columns
  - Created `increase_paylater_limit_on_payment()` function with trigger
  - **Initial limit**: Rp 2.500.000
  - **Max limit**: Rp 10.000.000
  - **Increase**: Rp 500.000 per milestone (3x on-time payments)

### 2. Repository Layer (paylater_repository.dart)
- ✅ `payWithPaylaterQris()` - Pay QRIS with PayLater
- ✅ `payWithPaylaterTransfer()` - Transfer with PayLater
- Both methods:
  - Check PayLater limit
  - Create transaction (qris_paylater / transfer_paylater)
  - Update used_limit
  - Create bill with interest calculation

### 3. Provider Layer (paylater_provider.dart)
- ✅ `payWithPaylaterQris()` - UI layer for QRIS PayLater
- ✅ `payWithPaylaterTransfer()` - UI layer for Transfer PayLater

### 4. Models
- ✅ Updated `PaylaterAccountModel` with limit increase tracking fields
- ✅ Added computed properties: `nextIncreaseProgress`, `paymentsNeededForIncrease`, `isMaxLimit`

### 5. UI Components
- ✅ `PaymentMethodSelector` widget - Reusable payment method picker with tenor
- ✅ Updated `TransferConfirmScreen` - Integrated payment selector
- ✅ Updated `QrisPaymentScreen` - Removed wallet balance blocking
- ✅ Updated `PaylaterScreen`:
  - Removed "Cairkan Dana" button
  - Added limit increase progress tracker
  - Grouped bills: Overdue, Active, Paid (History)
  - Visual progress bar (3-step indicator)

## 📋 Auto-Increase Limit System

### Rules:
1. **Initial Limit**: Rp 2.500.000
2. **Increase**: Rp 500.000 every 3 on-time payments
3. **Maximum**: Rp 10.000.000
4. **Cooldown**: Minimum 30 days between increases
5. **Penalty**: Counter resets to 0 if payment is late

### Progression Example:
- Start: Rp 2.500.000
- 3x on-time → Rp 3.000.000
- 3x on-time → Rp 3.500.000
- ... continues up to Rp 10.000.000

### How It Works:
- **Trigger**: Automatically when bill status changes to 'paid'
- **Check**: Was payment made on/before due_date?
  - ✅ Yes → Increment `on_time_payment_count`
  - ❌ No → Reset `on_time_payment_count` to 0, increment `late_payment_count`
- **Increase**: When `on_time_payment_count` reaches 3:
  - Add Rp 500.000 to `credit_limit` (max Rp 10jt)
  - Reset counter to 0
  - Set `last_limit_increase` timestamp

### UI Indicators:
- **Progress bar**: 3-step visual indicator
- **Text**: "2x lagi bayar tepat waktu → Rp 3.000.000"
- **Badge**: "Limit Maksimal Tercapai! 🎉" when at Rp 10jt
- **Stats**: Total bills paid, current progress

## 🚧 Remaining Work

### Critical Path:
1. ✅ ~~All code implementation~~ **DONE**
2. ⏳ **Run migration SQL in Supabase** - [paylater_payment_migration.sql](supabase/paylater_payment_migration.sql)
3. ⏳ **End-to-end testing**:
   - Test QRIS payment with PayLater
   - Test transfer with PayLater
   - Test limit increase on bill payment
   - Verify progress tracker UI

### Migration Steps:
1. Open Supabase Dashboard → SQL Editor
2. Copy content from `supabase/paylater_payment_migration.sql`
3. Execute the SQL
4. Verify new columns exist in `paylater_accounts` and `paylater_bills`
5. Test creating accounts (should have 2.5jt initial limit)

## Usage Flow

### QRIS Payment with PayLater:
```
1. Scan QR → Input amount
2. Select "PayLater" method
3. Choose tenor (1/3/6/12 months)
4. See: Amount + Interest = Total Due
5. Confirm → Transaction created + Bill generated
6. Merchant receives payment immediately
7. User pays bill before due date
```

### Transfer with PayLater:
```
1. Select user → Input amount
2. Select "PayLater" method  
3. Choose tenor
4. See calculation
5. Confirm → Recipient gets money + Bill created
6. User pays bill before due date
```

## Technical Notes

- Interest Rate: 2.5% per month
- Tenor Options: 1, 3, 6, 12 months
- Due Date: tenor_months × 30 days from transaction
- Calculation: total_due = principal + (principal × rate% × tenor)
- Limit Management: used_limit increases on payment, decreases when bill paid
