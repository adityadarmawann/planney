# 📊 Planney - Arsitektur & Flow Diagram

> Dokumentasi visual untuk memahami arsitektur aplikasi Planney dan alur kerja setiap fitur.

---

## 🏗️ Arsitektur Aplikasi (High-Level)

```
┌─────────────────────────────────────────────────────────────┐
│                         USER                                 │
│                       (Mobile App)                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Screens    │  │   Widgets    │  │  Providers   │      │
│  │  (View/UI)   │◄─┤  (Reusable)  │◄─┤   (State)    │      │
│  └──────────────┘  └──────────────┘  └───────┬──────┘      │
└────────────────────────────────────────────────┼────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                              │
│  ┌──────────────┐           ┌──────────────┐                │
│  │    Models    │◄──────────┤ Repositories │                │
│  │ (Data Class) │           │ (Bus. Logic) │                │
│  └──────────────┘           └──────┬───────┘                │
└────────────────────────────────────┼────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────┐
│               EXTERNAL SERVICES                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Supabase   │  │ Google Auth  │  │   Camera     │      │
│  │ (Backend DB) │  │  (OAuth)     │  │ (QR Scan)    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flow Diagram: Login

```
┌─────────────┐
│ SplashScreen│
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│ Check Auth Status│ (AuthProvider)
└──────┬───────────┘
       │
       ├─── Sudah Login ──► MainScreen (Home)
       │
       └─── Belum Login ──┐
                          ▼
                   ┌──────────────┐
                   │OnboardingScreen│
                   └──────┬─────────┘
                          │
                          ▼
                   ┌──────────────┐
                   │ LoginScreen  │
                   └──────┬───────┘
                          │
                ┌─────────┴─────────┐
                │                   │
                ▼                   ▼
        ┌──────────────┐    ┌──────────────┐
        │Email/Password│    │ Google Login │
        └──────┬───────┘    └──────┬───────┘
               │                   │
               └─────────┬─────────┘
                         │
                         ▼
                ┌─────────────────┐
                │  AuthRepository │
                │  .signIn()      │
                └─────────┬───────┘
                          │
                          ▼
                ┌─────────────────┐
                │    Supabase     │
                │  Auth Service   │
                └─────────┬───────┘
                          │
                ┌─────────┴─────────┐
                │                   │
                ▼                   ▼
            ✅ Success          ❌ Error
                │                   │
                ▼                   ▼
          MainScreen        Show Error Message
```

---

## 💸 Flow Diagram: Transfer

```
┌──────────────┐
│ HomeScreen   │
│ Click Transfer│
└──────┬───────┘
       │
       ▼
┌───────────────────┐
│TransferScreen     │ ← TransactionProvider.loadTransactions()
│(Pilih Penerima)   │ ← UserRepository.searchUsers()
└──────┬────────────┘
       │
       │ Select User
       ▼
┌───────────────────┐
│TransferConfirm    │
│(Input Amount)     │
│(Konfirmasi)       │
└──────┬────────────┘
       │
       │ Confirm Transfer
       ▼
┌────────────────────────────────┐
│ TransactionProvider.transfer() │
└──────┬─────────────────────────┘
       │
       ▼
┌────────────────────────────────┐
│ TransactionRepository          │
│ .createTransfer()              │
└──────┬─────────────────────────┘
       │
       ▼
┌────────────────────────────────┐
│ Supabase RPC Function          │
│ atomic_transfer()              │
│                                │
│ BEGIN TRANSACTION              │
│ 1. Check sender balance        │
│ 2. Update sender wallet (-amt) │
│ 3. Update receiver wallet (+amt)│
│ 4. Insert 2 transactions       │
│ COMMIT                         │
└──────┬─────────────────────────┘
       │
       ├─── ✅ Success ──► TransferSuccessScreen
       │                   └─► Update WalletProvider
       │
       └─── ❌ Failed ───► Show Error (Saldo tidak cukup, dll)
```

---

## 💰 Flow Diagram: Top Up

```
┌──────────────┐
│ HomeScreen   │
│ Click Top Up │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ TopUpScreen  │
│(Input Amount)│
└──────┬───────┘
       │
       │ Submit
       ▼
┌──────────────────────────────┐
│ TransactionProvider.topUp()  │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ TransactionRepository        │
│ .createTopUp()               │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ Supabase Database            │
│                              │
│ 1. Update wallet.balance     │
│ 2. Insert transaction record │
└──────┬───────────────────────┘
       │
       ├─── ✅ Success ──► TopUpSuccessScreen
       │                   └─► Update WalletProvider.balance
       │
       └─── ❌ Failed ───► Show Error
```

---

## 🏷️ Flow Diagram: Paylater

### Apply Limit

```
┌──────────────┐
│PaylaterScreen│
└──────┬───────┘
       │ Click "Apply"
       ▼
┌──────────────────┐
│PaylaterApplyScreen│
│(Select Limit)    │
└──────┬───────────┘
       │
       │ Submit
       ▼
┌──────────────────────────────┐
│ PaylaterProvider.applyLimit()│
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ PaylaterRepository           │
│ .applyPaylater()             │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ Create paylater_account      │
│ - credit_limit               │
│ - available_limit            │
│ - status: active             │
└──────┬───────────────────────┘
       │
       └─── ✅ Success ──► Navigate back
                           Update PaylaterProvider
```

### Use Paylater (Disbursement)

```
┌──────────────┐
│PaylaterScreen│
│ Click "Pakai"│
└──────┬───────┘
       │
       ▼
┌──────────────────────────────┐
│ Input amount (≤ available)   │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ PaylaterProvider             │
│ .createDisbursement()        │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ Supabase RPC                 │
│ paylater_disbursement()      │
│                              │
│ 1. Check available_limit     │
│ 2. Update wallet.balance (+) │
│ 3. Update available_limit    │
│ 4. Update outstanding_balance│
│ 5. Create paylater_bill      │
│ 6. Insert transaction record │
└──────┬───────────────────────┘
       │
       └─── ✅ Success ──► Update UI
                           Show success message
```

### Pay Bill

```
┌──────────────┐
│PaylaterScreen│
│ View Bills   │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│PaylaterBillScreen│
│ Select Bill      │
└──────┬───────────┘
       │ Pay
       ▼
┌──────────────────────────────┐
│ PaylaterProvider.payBill()   │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ Supabase RPC                 │
│ pay_paylater_bill()          │
│                              │
│ 1. Check wallet balance      │
│ 2. Update wallet.balance (-) │
│ 3. Update available_limit (+)│
│ 4. Update bill status: paid  │
│ 5. Insert transaction        │
└──────┬───────────────────────┘
       │
       └─── ✅ Success ──► Update UI
```

---

## 📊 Flow Diagram: Budget (MyPlan)

```
┌──────────────┐
│BudgetScreen  │ ← BudgetProvider.loadBudgets()
└──────┬───────┘
       │
       │ Click "Buat Anggaran"
       ▼
┌──────────────────┐
│BudgetCreateScreen│
│                  │
│ 1. Input Name    │
│ 2. Select Period │
│ 3. Add Items:    │
│    - Income      │
│    - Expense     │
└──────┬───────────┘
       │
       │ Submit
       ▼
┌──────────────────────────────┐
│ BudgetProvider.createBudget()│
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ BudgetRepository             │
│ .createBudget()              │
│                              │
│ 1. Insert to budgets table   │
│ 2. Insert budget_items       │
└──────┬───────────────────────┘
       │
       └─── ✅ Success ──► Navigate back
                           Reload budgets
```

### View Budget Detail

```
┌──────────────┐
│BudgetScreen  │
│ Select Budget│
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│BudgetDetailScreen│
│                  │
│ - Show Chart     │ ← BudgetChart widget (Pie)
│ - Income List    │
│ - Expense List   │
│ - Progress Bars  │
└──────────────────┘
```

---

## 📅 Flow Diagram: Expense Plan

```
┌─────────────────────────┐
│ExpensePlanCalendarScreen│ ← ExpensePlanProvider.loadPlans()
│(Calendar View)          │
└──────┬──────────────────┘
       │
       │ Click "Tambah Rencana"
       ▼
┌──────────────────────┐
│ExpensePlanCreateScreen│
│                      │
│ 1. Input Title       │
│ 2. Input Amount      │
│ 3. Select Category   │
│ 4. Pick Date         │
└──────┬───────────────┘
       │
       │ Submit
       ▼
┌────────────────────────────────┐
│ ExpensePlanProvider            │
│ .createExpensePlan()           │
└──────┬─────────────────────────┘
       │
       ▼
┌────────────────────────────────┐
│ ExpensePlanRepository          │
│ .createExpensePlan()           │
│                                │
│ Insert to expense_plans table  │
└──────┬─────────────────────────┘
       │
       └─── ✅ Success ──► Navigate back
                           Reload calendar
                           (Optional) Add to device calendar
```

### Mark as Completed

```
┌─────────────────────────┐
│ExpensePlanCalendarScreen│
│ Tap on plan             │
└──────┬──────────────────┘
       │
       │ Toggle Complete
       ▼
┌────────────────────────────────┐
│ ExpensePlanProvider            │
│ .toggleComplete()              │
└──────┬─────────────────────────┘
       │
       ▼
┌────────────────────────────────┐
│ Update is_completed in DB      │
└──────┬─────────────────────────┘
       │
       └─── Update UI (checkbox)
```

---

## 📱 Flow Diagram: QRIS

### Generate QR (Merchant Mode)

```
┌──────────────────┐
│QRISSimulatorScreen│
│ Tab: "Generate"  │
└──────┬───────────┘
       │
       │ Input amount
       ▼
┌──────────────────┐
│ Generate QR Code │ ← qr_flutter package
│                  │
│ Data: {          │
│   userId,        │
│   amount,        │
│   merchantName   │
│ }                │
└──────────────────┘
```

### Scan QR (Customer Mode)

```
┌──────────────────┐
│QRISSimulatorScreen│
│ Tab: "Scan"      │
└──────┬───────────┘
       │
       │ Open Camera
       ▼
┌──────────────────┐
│ Camera View      │ ← camera package
│ Scan QR Code     │
└──────┬───────────┘
       │
       │ QR Detected
       ▼
┌──────────────────┐
│ Parse QR Data    │
│ Extract:         │
│ - userId         │
│ - amount         │
│ - merchantName   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│QRISPaymentScreen │
│ Confirm Payment  │
└──────┬───────────┘
       │
       │ Confirm
       ▼
┌──────────────────────────────┐
│ TransactionProvider          │
│ .transfer()                  │
└──────┬───────────────────────┘
       │
       │ (Same flow as Transfer)
       ▼
    Success/Error
```

---

## 🔄 State Management Flow (Provider Pattern)

```
┌─────────────┐
│   Screen    │
└──────┬──────┘
       │
       │ 1. context.watch<Provider>() → Subscribe to state changes
       │
       ▼
┌─────────────┐      2. Auto rebuild when state changes
│  Provider   │◄─────────────────────────────────────┐
└──────┬──────┘                                      │
       │                                             │
       │ 3. Call method                              │
       │    context.read<Provider>().method()        │
       │                                             │
       ▼                                             │
┌─────────────┐                                      │
│ Repository  │                                      │
└──────┬──────┘                                      │
       │                                             │
       │ 4. Fetch/Update data                        │
       ▼                                             │
┌─────────────┐                                      │
│  Supabase   │                                      │
└──────┬──────┘                                      │
       │                                             │
       │ 5. Return data                              │
       ▼                                             │
┌─────────────┐                                      │
│ Repository  │                                      │
└──────┬──────┘                                      │
       │                                             │
       │ 6. Return to Provider                       │
       ▼                                             │
┌─────────────┐                                      │
│  Provider   │                                      │
│             │                                      │
│ 7. Update internal state                          │
│    _items = newData                                │
│    notifyListeners() ─────────────────────────────┘
│
└─────────────┘
```

**Example Code:**

```dart
// In Screen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 1. Subscribe (auto rebuild)
    final wallet = context.watch<WalletProvider>().wallet;
    
    return Column(
      children: [
        Text('Saldo: ${wallet?.balance}'),
        ElevatedButton(
          onPressed: () {
            // 3. Call method (no rebuild)
            context.read<WalletProvider>().loadWallet(userId);
          },
          child: Text('Refresh'),
        ),
      ],
    );
  }
}
```

---

## 🗄️ Database Schema Relationship

```
users (1) ──────────┬─────────► (1) wallets
    │               │
    │               │
    │ (1)           │ (1)
    │               │
    ▼               ▼
(Many)          (Many)
transactions    budgets
                    │
                    │ (1)
                    │
                    ▼
                (Many)
              budget_items


users (1) ──────────► (1) paylater_accounts
                           │
                           │ (1)
                           │
                           ▼
                       (Many)
                    paylater_bills


users (1) ──────────► (Many) expense_plans
```

---

## 📂 File Organization Pattern

```
Feature: Transfer
├── Presentation
│   ├── Screens
│   │   ├── transfer_screen.dart (List users)
│   │   ├── transfer_confirm_screen.dart (Confirm)
│   │   └── transfer_success_screen.dart (Success)
│   └── Widgets
│       └── (Reusable widgets jika ada)
│
├── Data
│   ├── Models
│   │   └── transaction_model.dart (Data structure)
│   └── Repositories
│       └── transaction_repository.dart (Business logic)
│
├── Provider
│   └── transaction_provider.dart (State management)
│
└── Database
    └── supabase/atomic_transfer_migration.sql (SQL)
```

---

## 🎯 Common Patterns

### Pattern 1: CRUD Operations

```dart
// CREATE
Future<Model> create(data) {
  1. Validate input
  2. Call repository.create()
  3. Insert to Supabase
  4. Return created model
  5. Update provider state
  6. notifyListeners()
}

// READ
Future<List<Model>> load() {
  1. Call repository.getAll()
  2. SELECT from Supabase
  3. Parse to List<Model>
  4. Update provider state
  5. notifyListeners()
}

// UPDATE
Future<void> update(id, data) {
  1. Validate input
  2. Call repository.update()
  3. UPDATE in Supabase
  4. Update local state
  5. notifyListeners()
}

// DELETE
Future<void> delete(id) {
  1. Call repository.delete()
  2. DELETE from Supabase
  3. Remove from local state
  4. notifyListeners()
}
```

### Pattern 2: Loading State

```dart
class FeatureProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Show loading
    
    try {
      final data = await _repository.getData();
      _items = data;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Hide loading
    }
  }
}
```

### Pattern 3: Navigation with Result

```dart
// Push & wait for result
final result = await Navigator.pushNamed(
  context,
  AppRoutes.createBudget,
);

if (result == true) {
  // Reload data
  context.read<BudgetProvider>().loadBudgets();
}

// Pop with result
Navigator.pop(context, true);
```

---

## 🔐 Authentication Flow Detail

```
┌─────────────────────────────────────────────────────┐
│                   App Startup                        │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│              Supabase.initialize()                   │
│  - Connect to backend                                │
│  - Restore session (if exists)                       │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│           AuthProvider.checkAuthStatus()             │
└────────────────────┬────────────────────────────────┘
                     │
         ┌───────────┴──────────┐
         ▼                      ▼
   Session exists         No session
         │                      │
         │                      ▼
         │              ┌─────────────┐
         │              │LoginScreen  │
         │              └─────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│         Load User Data                               │
│  1. Get user from Supabase Auth                      │
│  2. Load profile from users table                    │
│  3. Load wallet data                                 │
│  4. Initialize providers                             │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
              ┌─────────────┐
              │ MainScreen  │
              └─────────────┘
```

---

## 💡 Tips untuk Mengajar

### 1. **Mulai dari UI**
Ajarkan screen dulu, baru logic. Lebih mudah dipahami.

### 2. **Gunakan Diagram**
Gambar flow chart untuk setiap fitur.

### 3. **Live Coding**
Buat fitur sederhana dari awal:
- Screen → Widget → Provider → Repository → Supabase

### 4. **Debugging Bersama**
Ajak debug error bersama, explain proses troubleshooting.

### 5. **Code Reading**
Latih baca code yang sudah ada, pahami strukturnya.

### 6. **Small Tasks**
Beri tugas kecil:
- Ubah warna
- Tambah text field
- Buat widget baru
- Modify existing feature

---

## 📚 Learning Path Recommendation

```
Week 1: Basic Understanding
├─ Struktur folder
├─ Baca DEVELOPER_GUIDE.md
├─ Run aplikasi
└─ Explore UI (screens)

Week 2: Flutter Basics
├─ Widget basics (Container, Text, Column, Row)
├─ Stateless vs Stateful
├─ Navigation
└─ Edit existing screens

Week 3: State Management
├─ Provider pattern
├─ context.watch vs context.read
├─ notifyListeners()
└─ Modify existing providers

Week 4: Data Layer
├─ Models
├─ Repositories
├─ Supabase queries
└─ Add new field to model

Week 5: Build Feature
├─ Create simple CRUD feature
├─ Screen → Provider → Repository → DB
└─ Testing
```

---

**Dokumentasi ini membantu visualisasi alur kerja aplikasi Planney.  
Gunakan sebagai referensi saat mengajar atau onboarding developer baru.**

---

**Last Updated**: March 5, 2026

