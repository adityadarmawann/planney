# 📚 Developer Guide - Planney

> Panduan lengkap untuk developer yang ingin memahami, memodifikasi, dan mengembangkan source code Planney.

---

## 📑 Daftar Isi

- [Arsitektur Aplikasi](#-arsitektur-aplikasi)
- [Struktur Folder Detail](#-struktur-folder-detail)
- [Lokasi File untuk Setiap Fitur](#-lokasi-file-untuk-setiap-fitur)
- [Tools & Dependencies](#-tools--dependencies)
- [Cara Edit & Tambah Fitur](#-cara-edit--tambah-fitur)
- [State Management (Provider)](#-state-management-provider)
- [Database & Backend (Supabase)](#-database--backend-supabase)
- [Routing & Navigation](#-routing--navigation)
- [Styling & Theming](#-styling--theming)
- [Testing](#-testing)

---

## 🏗 Arsitektur Aplikasi

Planney menggunakan **Clean Architecture** dengan pattern:

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│  (UI, Widgets, Screens, Providers)      │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│           DATA LAYER                    │
│  (Models, Repositories)                 │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│        EXTERNAL SERVICES                │
│     (Supabase, Google Sign-In)          │
└─────────────────────────────────────────┘
```

### Pattern yang Digunakan:
- **Provider** untuk state management
- **Repository Pattern** untuk akses data
- **Widget Composition** untuk reusable components

---

## 📁 Struktur Folder Detail

```
lib/
├── core/                          # Core utilities & constants
│   ├── config/
│   │   └── env_config.dart       # Environment variables (Supabase keys)
│   ├── constants/
│   │   ├── app_colors.dart       # Warna aplikasi (primary, secondary, dll)
│   │   ├── app_routes.dart       # Named routes aplikasi
│   │   └── app_strings.dart      # Text constants
│   ├── errors/
│   │   └── app_exception.dart    # Custom exception handling
│   ├── theme/
│   │   └── app_theme.dart        # Theme configuration
│   └── utils/
│       ├── currency_formatter.dart   # Format Rupiah (Rp 10.000)
│       └── date_formatter.dart       # Format tanggal
│
├── data/                          # Data layer
│   ├── models/                    # Data models
│   │   ├── user_model.dart       # Model user (id, name, email, dll)
│   │   ├── wallet_model.dart     # Model wallet/dompet
│   │   ├── transaction_model.dart # Model transaksi
│   │   ├── budget_model.dart     # Model anggaran
│   │   ├── expense_plan_model.dart # Model rencana pengeluaran
│   │   └── paylater_*.dart       # Model paylater
│   │
│   └── repositories/              # Business logic & data access
│       ├── auth_repository.dart   # Login, register, logout
│       ├── user_repository.dart   # Get/update user profile
│       ├── wallet_repository.dart # Saldo, top up
│       ├── transaction_repository.dart  # Transfer, history
│       ├── budget_repository.dart       # CRUD budget
│       ├── paylater_repository.dart     # Paylater logic
│       └── expense_plan_repository.dart # Expense plans
│
├── providers/                     # State management (Provider)
│   ├── auth_provider.dart        # Auth state (login status, current user)
│   ├── user_provider.dart        # User profile state
│   ├── wallet_provider.dart      # Wallet balance state
│   ├── transaction_provider.dart # Transaction list state
│   ├── budget_provider.dart      # Budget state
│   ├── paylater_provider.dart    # Paylater state
│   └── expense_plan_provider.dart # Expense plan state
│
├── presentation/                  # UI Layer
│   ├── screens/                   # Halaman-halaman aplikasi
│   │   ├── auth/                 # Login, Register, Onboarding
│   │   │   ├── splash_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   │
│   │   ├── home/                 # Beranda
│   │   │   ├── main_screen.dart       # Bottom navigation wrapper
│   │   │   └── home_screen.dart       # Home/Beranda tab
│   │   │
│   │   ├── wallet/               # E-Wallet & Top Up
│   │   │   ├── wallet_screen.dart
│   │   │   ├── topup_screen.dart
│   │   │   └── topup_success_screen.dart
│   │   │
│   │   ├── transfer/             # Transfer & QRIS
│   │   │   ├── transfer_screen.dart
│   │   │   ├── transfer_confirm_screen.dart
│   │   │   ├── transfer_success_screen.dart
│   │   │   ├── qris_simulator_screen.dart
│   │   │   └── qris_payment_screen.dart
│   │   │
│   │   ├── paylater/             # Paylater
│   │   │   ├── paylater_screen.dart
│   │   │   ├── paylater_apply_screen.dart
│   │   │   └── paylater_bill_screen.dart
│   │   │
│   │   ├── budget/               # Budget/Anggaran (MyPlan)
│   │   │   ├── budget_screen.dart
│   │   │   ├── budget_create_screen.dart
│   │   │   └── budget_detail_screen.dart
│   │   │
│   │   ├── expense_plan/         # Rencana Pengeluaran
│   │   │   ├── expense_plan_calendar_screen.dart
│   │   │   └── expense_plan_create_screen.dart
│   │   │
│   │   ├── history/              # Riwayat Transaksi
│   │   │   ├── history_screen.dart
│   │   │   └── transaction_detail_screen.dart
│   │   │
│   │   └── profile/              # Profile
│   │       └── edit_profile_screen.dart
│   │
│   └── widgets/                   # Reusable widgets
│       ├── common/               # Widget umum (button, card, loading)
│       │   ├── sp_button.dart
│       │   ├── sp_card.dart
│       │   ├── sp_loading.dart
│       │   └── sp_text_field.dart
│       │
│       ├── home/                 # Widget khusus beranda
│       │   ├── balance_card.dart           # Card saldo di home
│       │   ├── quick_action_grid.dart      # 4 tombol (Top Up, Transfer, dll)
│       │   └── wallet_summary_chart.dart   # Chart ringkasan dompet
│       │
│       ├── budget/               # Widget budget
│       │   ├── budget_chart.dart
│       │   └── budget_progress_bar.dart
│       │
│       ├── transaction/          # Widget transaksi
│       │   └── transaction_tile.dart
│       │
│       └── payment/              # Widget payment
│           └── payment_method_card.dart
│
├── app.dart                       # Root widget, provider setup, routes
└── main.dart                      # Entry point aplikasi

supabase/                          # SQL migrations untuk database
├── schema.sql                     # Schema utama database
├── atomic_transfer_migration.sql  # Migration untuk atomic transfer
├── paylater_payment_migration.sql # Migration paylater
├── expense_plans_schema.sql       # Schema expense plans
└── ...                            # Migration-migration lainnya

assets/
├── images/                        # Gambar (logo, illustrations)
└── icons/                         # Icons SVG
```

---

## 🎯 Lokasi File untuk Setiap Fitur

### 1. **BERANDA (Home Screen)**

**Path utama:**
- 📄 **Screen**: `lib/presentation/screens/home/home_screen.dart`
- 📄 **Widget Saldo**: `lib/presentation/widgets/home/balance_card.dart`
- 📄 **Quick Actions**: `lib/presentation/widgets/home/quick_action_grid.dart`
- 📄 **Chart Ringkasan**: `lib/presentation/widgets/home/wallet_summary_chart.dart`
- 📄 **Provider**: `lib/providers/wallet_provider.dart`, `lib/providers/transaction_provider.dart`

**Cara ubah beranda:**
```dart
// Edit tampilan beranda
lib/presentation/screens/home/home_screen.dart

// Edit card saldo
lib/presentation/widgets/home/balance_card.dart

// Edit chart ringkasan dompet
lib/presentation/widgets/home/wallet_summary_chart.dart
```

---

### 2. **TRANSFER**

**Path utama:**
- 📄 **Screen pilih user**: `lib/presentation/screens/transfer/transfer_screen.dart`
- 📄 **Konfirmasi**: `lib/presentation/screens/transfer/transfer_confirm_screen.dart`
- 📄 **Success**: `lib/presentation/screens/transfer/transfer_success_screen.dart`
- 📄 **Repository**: `lib/data/repositories/transaction_repository.dart`
- 📄 **Provider**: `lib/providers/transaction_provider.dart`

**Cara ubah transfer:**
```dart
// Edit tampilan pilih penerima
lib/presentation/screens/transfer/transfer_screen.dart

// Edit logic transfer (atomic transaction)
lib/data/repositories/transaction_repository.dart
  → Method: createTransfer()

// Edit Supabase function
supabase/atomic_transfer_migration.sql
```

---

### 3. **QRIS**

**Path utama:**
- 📄 **Simulator QRIS**: `lib/presentation/screens/transfer/qris_simulator_screen.dart`
- 📄 **Payment**: `lib/presentation/screens/transfer/qris_payment_screen.dart`
- 📄 **Library**: `qr_flutter` (generate QR), `camera` (scan QR)

**Cara edit QRIS:**
```dart
// Edit tampilan scan/generate QR
lib/presentation/screens/transfer/qris_simulator_screen.dart
lib/presentation/screens/transfer/qris_payment_screen.dart
```

---

### 4. **TOP UP E-WALLET**

**Path utama:**
- 📄 **Screen**: `lib/presentation/screens/wallet/topup_screen.dart`
- 📄 **Success**: `lib/presentation/screens/wallet/topup_success_screen.dart`
- 📄 **Repository**: `lib/data/repositories/transaction_repository.dart`
- 📄 **Provider**: `lib/providers/transaction_provider.dart`

**Cara edit top up:**
```dart
// Edit tampilan top up
lib/presentation/screens/wallet/topup_screen.dart

// Edit logic top up
lib/data/repositories/transaction_repository.dart
  → Method: createTopUp()
```

---

### 5. **PAYLATER**

**Path utama:**
- 📄 **Screen utama**: `lib/presentation/screens/paylater/paylater_screen.dart`
- 📄 **Apply**: `lib/presentation/screens/paylater/paylater_apply_screen.dart`
- 📄 **Bill**: `lib/presentation/screens/paylater/paylater_bill_screen.dart`
- 📄 **Model**: `lib/data/models/paylater_account_model.dart`, `paylater_bill_model.dart`
- 📄 **Repository**: `lib/data/repositories/paylater_repository.dart`
- 📄 **Provider**: `lib/providers/paylater_provider.dart`

**Cara edit paylater:**
```dart
// Edit limit, bunga, dll
lib/data/repositories/paylater_repository.dart

// Edit database schema
supabase/paylater_payment_migration.sql
```

---

### 6. **BUDGET / MY PLAN (Anggaran)**

**Path utama:**
- 📄 **Screen list**: `lib/presentation/screens/budget/budget_screen.dart`
- 📄 **Create**: `lib/presentation/screens/budget/budget_create_screen.dart`
- 📄 **Detail**: `lib/presentation/screens/budget/budget_detail_screen.dart`
- 📄 **Widget chart**: `lib/presentation/widgets/budget/budget_chart.dart`
- 📄 **Model**: `lib/data/models/budget_model.dart`, `budget_item_model.dart`
- 📄 **Repository**: `lib/data/repositories/budget_repository.dart`
- 📄 **Provider**: `lib/providers/budget_provider.dart`

**Cara edit budget:**
```dart
// Edit tampilan budget
lib/presentation/screens/budget/budget_screen.dart

// Edit chart pie/bar
lib/presentation/widgets/budget/budget_chart.dart

// Edit logic CRUD budget
lib/data/repositories/budget_repository.dart
```

---

### 7. **RENCANA PENGELUARAN (Expense Plans)**

**Path utama:**
- 📄 **Calendar view**: `lib/presentation/screens/expense_plan/expense_plan_calendar_screen.dart`
- 📄 **Create**: `lib/presentation/screens/expense_plan/expense_plan_create_screen.dart`
- 📄 **Model**: `lib/data/models/expense_plan_model.dart`
- 📄 **Repository**: `lib/data/repositories/expense_plan_repository.dart`
- 📄 **Provider**: `lib/providers/expense_plan_provider.dart`
- 📄 **Database**: `supabase/expense_plans_schema.sql`

**Cara edit expense plans:**
```dart
// Edit tampilan kalender
lib/presentation/screens/expense_plan/expense_plan_calendar_screen.dart

// Edit form create
lib/presentation/screens/expense_plan/expense_plan_create_screen.dart
```

---

### 8. **RIWAYAT TRANSAKSI (History)**

**Path utama:**
- 📄 **Screen list**: `lib/presentation/screens/history/history_screen.dart`
- 📄 **Detail**: `lib/presentation/screens/history/transaction_detail_screen.dart`
- 📄 **Widget tile**: `lib/presentation/widgets/transaction/transaction_tile.dart`
- 📄 **Model**: `lib/data/models/transaction_model.dart`

**Cara edit history:**
```dart
// Edit tampilan list transaksi
lib/presentation/screens/history/history_screen.dart

// Edit card transaksi
lib/presentation/widgets/transaction/transaction_tile.dart

// Edit detail transaksi
lib/presentation/screens/history/transaction_detail_screen.dart
```

---

### 9. **PROFILE**

**Path utama:**
- 📄 **Screen**: `lib/presentation/screens/profile/edit_profile_screen.dart`
- 📄 **Model**: `lib/data/models/user_model.dart`
- 📄 **Repository**: `lib/data/repositories/user_repository.dart`
- 📄 **Provider**: `lib/providers/user_provider.dart`

**Cara edit profile:**
```dart
// Edit form profile
lib/presentation/screens/profile/edit_profile_screen.dart

// Edit logic update profile
lib/data/repositories/user_repository.dart
```

---

### 10. **LOGIN & REGISTER**

**Path utama:**
- 📄 **Splash**: `lib/presentation/screens/auth/splash_screen.dart`
- 📄 **Onboarding**: `lib/presentation/screens/auth/onboarding_screen.dart`
- 📄 **Login**: `lib/presentation/screens/auth/login_screen.dart`
- 📄 **Register**: `lib/presentation/screens/auth/register_screen.dart`
- 📄 **Repository**: `lib/data/repositories/auth_repository.dart`
- 📄 **Provider**: `lib/providers/auth_provider.dart`

**Cara edit auth:**
```dart
// Edit tampilan login
lib/presentation/screens/auth/login_screen.dart

// Edit logic login/register
lib/data/repositories/auth_repository.dart
```

---

## 🛠 Tools & Dependencies

### Framework & Language
- **Flutter** 3.x (Dart SDK >=3.0.0)
- **Dart** - Bahasa pemrograman

### State Management
- **provider** ^6.1.1 - State management pattern

### Backend & Database
- **supabase_flutter** ^2.3.0 - Backend as a Service (PostgreSQL + Auth + Storage)

### UI & Design
- **google_fonts** ^8.0.2 - Custom fonts
- **fl_chart** ^1.1.1 - Chart/grafik (bar chart, pie chart)
- **cached_network_image** ^3.3.0 - Cache gambar dari internet
- **shimmer** ^3.0.0 - Loading skeleton effect
- **flutter_animate** ^4.3.0 - Animasi

### QR Code
- **qr_flutter** ^4.1.0 - Generate QR code
- **camera** ^0.12.0 - Scan QR code (camera access)

### Calendar & Permissions
- **device_calendar** ^4.3.3 - Integrasi dengan kalender device
- **permission_handler** ^11.3.1 - Menangani permissions
- **timezone** ^0.9.4 - Timezone untuk calendar

### Authentication
- **google_sign_in** ^7.2.0 - Login dengan Google

### Utilities
- **intl** ^0.20.2 - Format currency, date (Indonesian locale)
- **uuid** ^4.2.1 - Generate unique ID
- **shared_preferences** ^2.2.2 - Local storage key-value
- **image_picker** ^1.0.5 - Pilih foto dari galeri/camera
- **url_launcher** ^6.2.2 - Buka URL/phone
- **path_provider** ^2.1.1 - Get app directory path

### Development Tools
- **flutter_lints** ^6.0.0 - Linter rules
- **flutter_launcher_icons** ^0.14.4 - Generate app icons

---

## ✏ Cara Edit & Tambah Fitur

### 1. **Menambah Screen Baru**

**Langkah-langkah:**

```dart
// 1. Buat file screen baru
lib/presentation/screens/nama_fitur/nama_screen.dart

// 2. Buat widget stateful
import 'package:flutter/material.dart';

class NamaScreen extends StatefulWidget {
  const NamaScreen({super.key});

  @override
  State<NamaScreen> createState() => _NamaScreenState();
}

class _NamaScreenState extends State<NamaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Judul Screen')),
      body: Center(child: Text('Content')),
    );
  }
}

// 3. Tambahkan route di lib/core/constants/app_routes.dart
class AppRoutes {
  static const String namaFitur = '/nama-fitur';
}

// 4. Tambahkan di routes di lib/app.dart
routes: {
  AppRoutes.namaFitur: (context) => const NamaScreen(),
}

// 5. Navigate dari screen lain
Navigator.pushNamed(context, AppRoutes.namaFitur);
```

---

### 2. **Menambah Widget Reusable**

```dart
// 1. Buat file di lib/presentation/widgets/common/
lib/presentation/widgets/common/custom_widget.dart

// 2. Buat widget
import 'package:flutter/material.dart';

class CustomWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const CustomWidget({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Text(text),
      ),
    );
  }
}

// 3. Gunakan di screen
import '../../widgets/common/custom_widget.dart';

CustomWidget(
  text: 'Hello',
  onTap: () => print('Tapped'),
)
```

---

### 3. **Menambah Model Baru**

```dart
// 1. Buat file model
lib/data/models/nama_model.dart

// 2. Buat class model
class NamaModel {
  final String id;
  final String nama;
  final DateTime createdAt;

  const NamaModel({
    required this.id,
    required this.nama,
    required this.createdAt,
  });

  // Konversi dari JSON (Supabase)
  factory NamaModel.fromJson(Map<String, dynamic> json) {
    return NamaModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

---

### 4. **Menambah Repository**

```dart
// 1. Buat file repository
lib/data/repositories/nama_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nama_model.dart';
import '../../core/errors/app_exception.dart';

class NamaRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get data
  Future<List<NamaModel>> getData() async {
    try {
      final response = await _supabase
          .from('table_name')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => NamaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw AppException('Gagal mengambil data: $e');
    }
  }

  // Create data
  Future<NamaModel> createData(String nama) async {
    try {
      final response = await _supabase
          .from('table_name')
          .insert({'nama': nama})
          .select()
          .single();
      
      return NamaModel.fromJson(response);
    } catch (e) {
      throw AppException('Gagal membuat data: $e');
    }
  }
}
```

---

### 5. **Menambah Provider (State Management)**

```dart
// 1. Buat file provider
lib/providers/nama_provider.dart

import 'package:flutter/foundation.dart';
import '../data/models/nama_model.dart';
import '../data/repositories/nama_repository.dart';
import '../core/errors/app_exception.dart';

class NamaProvider extends ChangeNotifier {
  final NamaRepository _repository;

  List<NamaModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  NamaProvider({required NamaRepository repository})
      : _repository = repository;

  // Getters
  List<NamaModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load data
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.getData();
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create data
  Future<bool> createData(String nama) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newItem = await _repository.createData(nama);
      _items.insert(0, newItem);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// 2. Register provider di lib/app.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => NamaProvider(
        repository: NamaRepository(),
      ),
    ),
  ],
)

// 3. Pakai di screen
final provider = context.watch<NamaProvider>();
final items = provider.items;
final isLoading = provider.isLoading;

// 4. Call method
context.read<NamaProvider>().loadData();
```

---

### 6. **Mengubah Warna Aplikasi**

```dart
// Edit file:
lib/core/constants/app_colors.dart

class AppColors {
  // Primary color (biru)
  static const Color primary = Color(0xFF0052CC);
  static const Color primaryLight = Color(0xFF0066FF);
  
  // Secondary color (orange)
  static const Color secondary = Color(0xFFFFA500);
  
  // Income/Expense colors
  static const Color income = Color(0xFF1DBE4A);   // Hijau
  static const Color expense = Color(0xFFE85547);  // Merah
  
  // Background
  static const Color background = Color(0xFFFAFBFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF0F1929);
  static const Color textSecondary = Color(0xFF66758E);
}
```

---

### 7. **Menambah String Constants**

```dart
// Edit file:
lib/core/constants/app_strings.dart

class AppStrings {
  static const String appName = 'Planney';
  static const String quickActions = 'Aksi Cepat';
  static const String recentTransactions = 'Transaksi Terbaru';
  
  // Tambahkan string baru
  static const String yourNewString = 'Text Baru';
}

// Pakai di screen
Text(AppStrings.yourNewString)
```

---

## 🔄 State Management (Provider)

### Cara Menggunakan Provider

```dart
// 1. WATCH - Auto rebuild saat data berubah
final wallet = context.watch<WalletProvider>().wallet;
final balance = wallet?.balance ?? 0;

// 2. READ - Tidak rebuild, untuk call method
context.read<WalletProvider>().loadWallet(userId);

// 3. SELECT - Subscribe ke property tertentu saja
final balance = context.select<WalletProvider, double>(
  (provider) => provider.wallet?.balance ?? 0,
);
```

### Provider yang Tersedia

| Provider | Fungsi | Path |
|----------|--------|------|
| `AuthProvider` | Login, register, logout | `lib/providers/auth_provider.dart` |
| `UserProvider` | User profile | `lib/providers/user_provider.dart` |
| `WalletProvider` | Saldo wallet | `lib/providers/wallet_provider.dart` |
| `TransactionProvider` | List transaksi | `lib/providers/transaction_provider.dart` |
| `BudgetProvider` | Budget/anggaran | `lib/providers/budget_provider.dart` |
| `PaylaterProvider` | Paylater account & bills | `lib/providers/paylater_provider.dart` |
| `ExpensePlanProvider` | Expense plans | `lib/providers/expense_plan_provider.dart` |

---

## 🗄 Database & Backend (Supabase)

### Tabel Database Utama

```sql
-- users: Data user
id, email, full_name, phone, avatar_url, username, created_at, updated_at

-- wallets: E-Wallet
id, user_id, balance, created_at, updated_at

-- transactions: Semua transaksi
id, sender_id, receiver_id, wallet_id, type, amount, fee, status, note, ref_code, created_at

-- budgets: Anggaran
id, user_id, name, start_date, end_date, created_at

-- budget_items: Item dalam anggaran
id, budget_id, category, amount, type (income/expense)

-- paylater_accounts: Akun paylater user
id, user_id, credit_limit, available_limit, outstanding_balance, status

-- paylater_bills: Tagihan paylater
id, account_id, amount, due_date, status, late_fee

-- expense_plans: Rencana pengeluaran
id, user_id, title, amount, category, date, is_completed
```

### Cara Query Supabase

```dart
// SELECT
final data = await Supabase.instance.client
    .from('table_name')
    .select()
    .eq('user_id', userId);

// INSERT
final result = await Supabase.instance.client
    .from('table_name')
    .insert({'column': 'value'})
    .select()
    .single();

// UPDATE
await Supabase.instance.client
    .from('table_name')
    .update({'column': 'new_value'})
    .eq('id', id);

// DELETE
await Supabase.instance.client
    .from('table_name')
    .delete()
    .eq('id', id);

// CALL RPC Function
final result = await Supabase.instance.client
    .rpc('function_name', params: {'param': 'value'});
```

### Lokasi SQL Migrations

```
supabase/
├── schema.sql                      # Schema utama (semua tabel)
├── atomic_transfer_migration.sql   # RPC untuk transfer atomic
├── paylater_payment_migration.sql  # RPC untuk pembayaran paylater
├── expense_plans_schema.sql        # Tabel expense_plans
└── ...
```

---

## 🗺 Routing & Navigation

### Named Routes

```dart
// Definisi route
lib/core/constants/app_routes.dart

// Setup routes
lib/app.dart → MaterialApp(routes: {...})

// Navigate
Navigator.pushNamed(context, AppRoutes.transfer);

// Navigate dengan argument
Navigator.pushNamed(
  context, 
  AppRoutes.transactionDetail,
  arguments: transaction,
);

// Pop (kembali)
Navigator.pop(context);

// Pop dengan result
Navigator.pop(context, result);

// Replace (tidak bisa back)
Navigator.pushReplacementNamed(context, AppRoutes.home);
```

### Route List Lengkap

```dart
AppRoutes.splash           // Splash screen
AppRoutes.onboarding       // Onboarding
AppRoutes.login            // Login
AppRoutes.register         // Register
AppRoutes.home             // Main screen (bottom nav)
AppRoutes.topup            // Top up
AppRoutes.transfer         // Transfer
AppRoutes.paylater         // Paylater
AppRoutes.budgetCreate     // Buat budget
AppRoutes.expensePlanCalendar  // Kalender expense
AppRoutes.history          // Riwayat transaksi
AppRoutes.editProfile      // Edit profile
```

---

## 🎨 Styling & Theming

### Menggunakan AppColors

```dart
import '../../../core/constants/app_colors.dart';

Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)
```

### Menggunakan Custom Theme

```dart
// lib/core/theme/app_theme.dart sudah setup theme

// Button theme
ElevatedButton(
  onPressed: () {},
  child: Text('Button'),
)

// TextField theme
TextField(
  decoration: InputDecoration(
    labelText: 'Label',
  ),
)
```

### Format Currency

```dart
import '../../../core/utils/currency_formatter.dart';

final formatted = CurrencyFormatter.format(100000);
// Output: Rp 100.000
```

### Format Date

```dart
import '../../../core/utils/date_formatter.dart';

final formatted = DateFormatter.formatDate(DateTime.now());
// Output: 5 Mar 2026

final withTime = DateFormatter.formatDateTime(DateTime.now());
// Output: 5 Mar 2026, 14:30
```

---

## 🧪 Testing

### Run Tests

```bash
# Run semua tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run dengan coverage
flutter test --coverage
```

### Struktur Test

```
test/
├── widget_test.dart       # Widget tests
├── unit_test.dart         # Unit tests (model, repository)
└── integration_test.dart  # Integration tests
```

---

## 🚀 Development Workflow

### 1. **Pull Latest Code**
```bash
git pull origin main
```

### 2. **Create Feature Branch**
```bash
git checkout -b feature/nama-fitur
```

### 3. **Development**
```bash
# Run app
flutter run

# Hot reload (dalam terminal)
r

# Hot restart
R

# Quit
q
```

### 4. **Commit Changes**
```bash
git add .
git commit -m "feat: deskripsi fitur"
```

### 5. **Push & Merge**
```bash
git push origin feature/nama-fitur
# Create pull request di GitHub
```

---

## 📝 Commit Message Convention

```
feat: Menambah fitur baru
fix: Memperbaiki bug
docs: Update dokumentasi
style: Format code (tidak mengubah logic)
refactor: Refactor code
test: Menambah test
chore: Update dependencies, config, dll
```

---

## 🐛 Common Issues & Solutions

### 1. **Error: Supabase not initialized**
```dart
// Pastikan sudah init di main.dart
await Supabase.initialize(
  url: EnvConfig.supabaseUrl,
  anonKey: EnvConfig.supabaseAnonKey,
);
```

### 2. **Provider not found**
```dart
// Pastikan provider sudah di-register di app.dart
// Dan gunakan context yang benar (di bawah MultiProvider)
```

### 3. **Chart tidak muncul**
```dart
// Pastikan chart widget punya ukuran (height/width)
SizedBox(
  height: 200,
  child: BarChart(...),
)
```

### 4. **Hot reload tidak jalan**
```bash
# Restart app
flutter run
```

---

## 📚 Resources & Documentation

- **Flutter**: https://docs.flutter.dev/
- **Dart**: https://dart.dev/guides
- **Supabase**: https://supabase.com/docs
- **Provider**: https://pub.dev/packages/provider
- **fl_chart**: https://pub.dev/packages/fl_chart

---

## 👥 Contact & Support

Jika ada pertanyaan atau butuh bantuan:
1. Baca dokumentasi ini dulu
2. Check file README.md untuk setup awal
3. Lihat code yang sudah ada untuk referensi
4. Search di Google/Stack Overflow

---

**Happy Coding! 🚀**

---

**Document Version**: 1.0  
**Last Updated**: March 5, 2026  
**Maintained by**: Planney Dev Team

