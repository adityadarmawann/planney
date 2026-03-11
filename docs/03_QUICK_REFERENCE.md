# 🎯 Quick Reference - Planney

> Cheat sheet untuk developer Planney. Referensi cepat lokasi file dan cara edit fitur.

---

## 📍 Lokasi File Penting (Quick Map)

### 🏠 BERANDA
```
Screen:  lib/presentation/screens/home/home_screen.dart
Widgets: lib/presentation/widgets/home/
  ├── balance_card.dart          (Card saldo)
  ├── quick_action_grid.dart     (4 tombol aksi)
  └── wallet_summary_chart.dart  (Chart bar)
```

### 💸 TRANSFER
```
Screens: lib/presentation/screens/transfer/
  ├── transfer_screen.dart         (Pilih penerima)
  ├── transfer_confirm_screen.dart (Konfirmasi)
  └── transfer_success_screen.dart (Sukses)

Logic:   lib/data/repositories/transaction_repository.dart
SQL:     supabase/atomic_transfer_migration.sql
```

### 📱 QRIS
```
Screens: lib/presentation/screens/transfer/
  ├── qris_simulator_screen.dart  (Generate/Scan QR)
  └── qris_payment_screen.dart    (Payment)
```

### 💰 TOP UP
```
Screens: lib/presentation/screens/wallet/
  ├── topup_screen.dart          (Input amount)
  └── topup_success_screen.dart  (Sukses)

Logic:   lib/data/repositories/transaction_repository.dart
         → Method: createTopUp()
```

### 🏷️ PAYLATER
```
Screens: lib/presentation/screens/paylater/
  ├── paylater_screen.dart       (Dashboard)
  ├── paylater_apply_screen.dart (Apply limit)
  └── paylater_bill_screen.dart  (Bayar tagihan)

Models:  lib/data/models/
  ├── paylater_account_model.dart
  └── paylater_bill_model.dart

Repo:    lib/data/repositories/paylater_repository.dart
SQL:     supabase/paylater_payment_migration.sql
```

### 📊 BUDGET / MY PLAN
```
Screens: lib/presentation/screens/budget/
  ├── budget_screen.dart         (List budget)
  ├── budget_create_screen.dart  (Create)
  └── budget_detail_screen.dart  (Detail)

Widgets: lib/presentation/widgets/budget/
  ├── budget_chart.dart          (Pie chart)
  └── budget_progress_bar.dart   (Progress bar)

Models:  lib/data/models/
  ├── budget_model.dart
  └── budget_item_model.dart
```

### 📅 RENCANA PENGELUARAN
```
Screens: lib/presentation/screens/expense_plan/
  ├── expense_plan_calendar_screen.dart  (Kalender)
  └── expense_plan_create_screen.dart    (Create)

Model:   lib/data/models/expense_plan_model.dart
SQL:     supabase/expense_plans_schema.sql
```

### 📜 RIWAYAT
```
Screens: lib/presentation/screens/history/
  ├── history_screen.dart           (List)
  └── transaction_detail_screen.dart (Detail)

Widget:  lib/presentation/widgets/transaction/transaction_tile.dart
```

### 👤 PROFILE
```
Screen: lib/presentation/screens/profile/edit_profile_screen.dart
Model:  lib/data/models/user_model.dart
Repo:   lib/data/repositories/user_repository.dart
```

### 🔐 AUTH
```
Screens: lib/presentation/screens/auth/
  ├── splash_screen.dart
  ├── onboarding_screen.dart
  ├── login_screen.dart
  └── register_screen.dart

Repo:    lib/data/repositories/auth_repository.dart
```

---

## ⚙️ Core Files (Sering Diubah)

### Warna
```dart
lib/core/constants/app_colors.dart

// Edit warna
static const Color primary = Color(0xFF0052CC);
static const Color income = Color(0xFF1DBE4A);  // Hijau
static const Color expense = Color(0xFFE85547); // Merah
```

### Routes
```dart
lib/core/constants/app_routes.dart

// Tambah route baru
static const String namaRoute = '/nama-route';

// Setup di lib/app.dart
routes: {
  AppRoutes.namaRoute: (context) => NamaScreen(),
}
```

### Strings
```dart
lib/core/constants/app_strings.dart

// Tambah string
static const String newText = 'Text Baru';
```

### Format Currency
```dart
lib/core/utils/currency_formatter.dart

CurrencyFormatter.format(100000)  // Rp 100.000
```

### Format Date
```dart
lib/core/utils/date_formatter.dart

DateFormatter.formatDate(DateTime.now())      // 5 Mar 2026
DateFormatter.formatDateTime(DateTime.now())  // 5 Mar 2026, 14:30
```

---

## 🔧 Common Tasks

### 1. Ubah Teks di Screen
```dart
// Cari file screen
lib/presentation/screens/nama_folder/nama_screen.dart

// Edit Text widget
Text('Teks Baru')
```

### 2. Ubah Warna Button/Card
```dart
// Import colors
import '../../../core/constants/app_colors.dart';

// Pakai warna
Container(color: AppColors.primary)
ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary))
```

### 3. Tambah Field di Form
```dart
// Tambah TextField
TextField(
  decoration: InputDecoration(
    labelText: 'Label Baru',
    prefixIcon: Icon(Icons.icon_name),
  ),
)
```

### 4. Ubah Chart/Graph
```dart
// Edit chart widget
lib/presentation/widgets/budget/budget_chart.dart      (Pie chart)
lib/presentation/widgets/home/wallet_summary_chart.dart (Bar chart)

// Ubah warna bar
BarChartRodData(
  toY: amount,
  color: AppColors.income,  // <- Ubah warna di sini
)
```

### 5. Tambah Item di List
```dart
// Tambah ke ListView.builder
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ListTile(
      title: Text(item.name),
      onTap: () {},
    );
  },
)
```

### 6. Navigate ke Screen Lain
```dart
// Push
Navigator.pushNamed(context, AppRoutes.namaRoute);

// Push dengan data
Navigator.pushNamed(context, AppRoutes.detail, arguments: data);

// Pop (kembali)
Navigator.pop(context);
```

### 7. Call API Supabase
```dart
// SELECT
final data = await Supabase.instance.client
    .from('table_name')
    .select()
    .eq('user_id', userId);

// INSERT
await Supabase.instance.client
    .from('table_name')
    .insert({'column': 'value'});

// UPDATE
await Supabase.instance.client
    .from('table_name')
    .update({'column': 'new_value'})
    .eq('id', id);
```

### 8. Gunakan Provider
```dart
// Watch (auto rebuild)
final data = context.watch<NamaProvider>().data;

// Read (call method, no rebuild)
context.read<NamaProvider>().loadData();

// Select (subscribe property tertentu)
final count = context.select<NamaProvider, int>(
  (provider) => provider.items.length,
);
```

### 9. Show Loading
```dart
// Gunakan widget SpLoading
import '../../widgets/common/sp_loading.dart';

if (isLoading)
  const SpLoading()
else
  YourContent()
```

### 10. Show Snackbar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Pesan sukses')),
);
```

---

## 🗄️ Database Tables Quick Ref

```
users              → Data user (id, email, full_name, username)
wallets            → Saldo (id, user_id, balance)
transactions       → Semua transaksi (type, amount, fee, status)
budgets            → Anggaran (name, start_date, end_date)
budget_items       → Item budget (category, amount, type)
paylater_accounts  → Akun paylater (credit_limit, available_limit)
paylater_bills     → Tagihan (amount, due_date, late_fee, status)
expense_plans      → Rencana (title, amount, date, is_completed)
```

---

## 📦 Main Dependencies

```yaml
supabase_flutter: ^2.3.0      # Backend
provider: ^6.1.1              # State management
fl_chart: ^1.1.1              # Charts/graphs
google_sign_in: ^7.2.0        # Google login
qr_flutter: ^4.1.0            # Generate QR
camera: ^0.12.0               # Scan QR
device_calendar: ^4.3.3       # Calendar
intl: ^0.20.2                 # Format Rupiah/date
```

---

## 🎨 Common Widgets

```dart
// Button
ElevatedButton(onPressed: () {}, child: Text('Text'))

// Card
Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Content')))

// Custom Card (dari app)
SpCard(child: Text('Content'))

// TextField
TextField(decoration: InputDecoration(labelText: 'Label'))

// Loading
CircularProgressIndicator()
SpLoading()  // Custom loading dari app

// Icon
Icon(Icons.account_balance_wallet)

// Image
Image.asset('assets/images/logo.png')
```

---

## 🛠️ Flutter Commands

```bash
# Run app
flutter run

# Hot reload (dalam terminal yang running)
r

# Hot restart
R

# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk --release

# Check devices
flutter devices

# Run di device tertentu
flutter run -d device_id

# Run dengan env file
flutter run --dart-define-from-file=.env
```

---

## 🔍 Debugging Tips

### 1. Print Debug
```dart
print('Debug: $variable');
debugPrint('Debug message');
```

### 2. Check Provider State
```dart
print('Loading: ${provider.isLoading}');
print('Error: ${provider.errorMessage}');
print('Data: ${provider.items}');
```

### 3. Check Navigation
```dart
print('Current route: ${ModalRoute.of(context)?.settings.name}');
```

### 4. Flutter Inspector
```bash
# Run app dengan DevTools
flutter run
# Buka di browser, ada link di terminal
```

---

## 📱 App Structure Overview

```
Main Entry
└─ main.dart
   └─ App (MultiProvider setup)
      └─ MaterialApp (routes, theme)
         └─ SplashScreen
            └─ LoginScreen / MainScreen
               └─ MainScreen (Bottom Navigation)
                  ├─ HomeScreen (Tab 1)
                  ├─ BudgetScreen (Tab 2)
                  ├─ QR Scanner (Tab 3)
                  ├─ HistoryScreen (Tab 4)
                  └─ ProfileScreen (Tab 5)
```

---

## 🎯 Top 10 Most Edited Files

1. `lib/presentation/screens/home/home_screen.dart` - Beranda
2. `lib/presentation/screens/budget/budget_screen.dart` - MyPlan
3. `lib/core/constants/app_colors.dart` - Warna
4. `lib/presentation/widgets/home/wallet_summary_chart.dart` - Chart beranda
5. `lib/presentation/screens/transfer/transfer_screen.dart` - Transfer
6. `lib/data/repositories/transaction_repository.dart` - Logic transaksi
7. `lib/presentation/screens/paylater/paylater_screen.dart` - Paylater
8. `lib/core/constants/app_strings.dart` - Teks
9. `lib/presentation/screens/auth/login_screen.dart` - Login
10. `lib/app.dart` - Routes & providers

---

## 🚨 Quick Fixes

### "Provider not found"
```dart
// Pastikan context di bawah MultiProvider
// Atau wrap widget dengan Consumer/Builder
```

### "setState() called after dispose"
```dart
// Check mounted before setState
if (mounted) {
  setState(() {});
}
```

### "RenderBox not laid out"
```dart
// Wrap dengan SizedBox/Container dengan ukuran
SizedBox(
  height: 200,
  child: YourWidget(),
)
```

### Hot reload tidak jalan
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📞 Contact

Butuh bantuan? Baca:
1. **DEVELOPER_GUIDE.md** - Dokumentasi lengkap
2. **README.md** - Setup & installation
3. Code comments di file-file penting

---

**Last Updated**: March 5, 2026

