# Planney

> Aplikasi mobile Flutter untuk perencanaan keuangan dengan identitas baru Planney.
> Fitur lengkap: E-Wallet, Transfer, QRIS, Paylater, Financial Planner — semua dalam bahasa Indonesia dengan simulasi Rupiah.

📚 **[Lihat Dokumentasi Developer](docs/01_INDEX.md)** - Panduan lengkap untuk developer

---

## �📋 Daftar Isi

- [Fitur Aplikasi](#-fitur-aplikasi)
- [Tech Stack](#-tech-stack)
- [Prasyarat — Apa Saja yang Harus Diinstall](#-prasyarat--apa-saja-yang-harus-diinstall)
- [Langkah 1: Install Flutter SDK](#langkah-1-install-flutter-sdk)
- [Langkah 2: Install Android Studio & Emulator](#langkah-2-install-android-studio--emulator)
- [Langkah 3: Install Git](#langkah-3-install-git)
- [Langkah 4: Install Code Editor (VS Code)](#langkah-4-install-code-editor-vs-code)
- [Langkah 5: Clone Project & Install Dependencies](#langkah-5-clone-project--install-dependencies)
- [Langkah 6: Setup Supabase (Backend & Database)](#langkah-6-setup-supabase-backend--database)
- [Langkah 7: Konfigurasi Environment](#langkah-7-konfigurasi-environment)
- [Langkah 8: Setup Google Sign-In (Opsional)](#langkah-8-setup-google-sign-in-opsional)
- [Langkah 9: Jalankan Aplikasi (Development)](#langkah-9-jalankan-aplikasi-development)
- [Langkah 10: Test di HP Android via WiFi](#langkah-10-test-di-hp-android-via-wifi)
- [Langkah 11: Build APK (File Instalasi Android)](#langkah-11-build-apk-file-instalasi-android)
- [Struktur Folder](#-struktur-folder)
- [Database Schema](#-database-schema)
- [Troubleshooting](#-troubleshooting)

---

## ✨ Fitur Aplikasi

| Fitur | Keterangan |
|-------|------------|
| 🔐 Login & Register | Email + Password, Google Sign-In |
| 👤 Profil Pengguna | Lihat & edit profil (nama, avatar, phone) |
| 💰 E-Wallet | Saldo digital dalam Rupiah + Top Up (simulasi) |
| 💸 Transfer | Antar pengguna Planney |
| 🏦 Transfer Bank | Simulasi transfer ke BCA, BNI, BRI, Mandiri, dll |
| 📱 QRIS | Simulasi pembayaran via QR Code |
| 🏷️ Paylater | Simulasi pinjaman (limit Rp 1.000.000, bunga 2.5%/bulan) |
| 📊 Financial Planner | Budget mingguan/bulanan/kustom + chart visualisasi |
| 📜 Riwayat Transaksi | List semua transaksi + filter + detail |

---

## 🛠 Tech Stack

| Komponen | Teknologi |
|----------|-----------|
| Mobile App | Flutter (Dart) |
| Backend & Database | Supabase (PostgreSQL + Auth + Storage) |
| State Management | Provider |
| Login Google | Google Sign-In |
| Chart/Grafik | fl_chart |
| Format Mata Uang | intl (locale id_ID) — Rp 1.000.000 |

---

## 📦 Prasyarat — Apa Saja yang Harus Diinstall

Sebelum mulai, pastikan kamu sudah menginstall semua tools berikut di **PC/Laptop** kamu:

| # | Software | Kegunaan | Download |
|---|----------|----------|----------|
| 1 | **Flutter SDK** | Framework untuk membuat aplikasi | [flutter.dev/get-started](https://docs.flutter.dev/get-started/install) |
| 2 | **Android Studio** | Emulator Android + Android SDK | [developer.android.com](https://developer.android.com/studio) |
| 3 | **Git** | Version control & clone repository | [git-scm.com](https://git-scm.com/downloads) |
| 4 | **VS Code** (opsional) | Code editor yang ringan | [code.visualstudio.com](https://code.visualstudio.com/) |
| 5 | **Chrome** | Untuk akses Supabase Dashboard | Sudah ada biasanya |

### Sistem Operasi yang Didukung
- ✅ Windows 10/11 (64-bit)
- ✅ macOS 11 (Big Sur) ke atas
- ✅ Linux (Ubuntu 20.04 ke atas)

---

## Langkah 1: Install Flutter SDK

### Windows

1. Download Flutter SDK dari [flutter.dev](https://docs.flutter.dev/get-started/install/windows/mobile)
2. Extract zip ke folder, contoh: `C:\flutter`
3. Tambahkan Flutter ke **System PATH**:
   - Buka **Settings** → cari "Environment Variables"
   - Di **System variables**, klik `Path` → **Edit** → **New**
   - Tambahkan: `C:\flutter\bin`
   - Klik **OK** semua
4. Buka **Command Prompt** baru, ketik:
   ```bash
   flutter --version
   ```
   Jika muncul versi Flutter, berarti berhasil ✅

### macOS

```bash
# Menggunakan Homebrew (paling mudah)
brew install --cask flutter

# Atau download manual dari flutter.dev dan extract
# Tambahkan ke PATH di ~/.zshrc:
export PATH="$HOME/flutter/bin:$PATH"

# Verifikasi
flutter --version
```

### Linux

```bash
# Menggunakan snap
sudo snap install flutter --classic

# Verifikasi
flutter --version
```

### Cek Kesiapan Flutter

Setelah install, jalankan **Flutter Doctor** untuk cek apakah semua sudah siap:

```bash
flutter doctor
```

Pastikan output menunjukkan ✅ (centang hijau) untuk:
- Flutter
- Android toolchain
- Android Studio
- Connected device (atau Chrome)

Jika ada ❌ atau ⚠️, ikuti instruksi yang ditampilkan untuk memperbaiki.

---

## Langkah 2: Install Android Studio & Emulator

Android Studio diperlukan untuk **Android SDK** dan **Emulator** (HP virtual).

### Install Android Studio

1. Download dari [developer.android.com/studio](https://developer.android.com/studio)
2. Install dengan pengaturan default
3. Buka Android Studio → **More Actions** → **SDK Manager**
4. Di tab **SDK Platforms**, centang:
   - ✅ Android 14.0 (API 34) atau yang terbaru
5. Di tab **SDK Tools**, centang:
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Command-line Tools
   - ✅ Android Emulator
   - ✅ Android SDK Platform-Tools
6. Klik **Apply** → Download & Install

### Buat Emulator (HP Virtual)

1. Buka Android Studio → **More Actions** → **Virtual Device Manager**
2. Klik **Create Device**
3. Pilih **Pixel 7** (atau HP apapun) → **Next**
4. Pilih system image **API 34** → **Download** jika belum ada → **Next**
5. Klik **Finish**
6. Klik tombol ▶️ (Play) untuk menjalankan emulator

> 💡 **Tanpa emulator?** Kamu juga bisa langsung test di HP Android asli (lihat Langkah 10).

### Accept Android Licenses

```bash
flutter doctor --android-licenses
```

Ketik `y` untuk semua pertanyaan.

---

## Langkah 3: Install Git

### Windows
1. Download dari [git-scm.com/downloads](https://git-scm.com/downloads)
2. Install dengan pengaturan default
3. Verifikasi:
   ```bash
   git --version
   ```

### macOS
```bash
# Biasanya sudah pre-installed. Jika belum:
xcode-select --install
```

### Linux
```bash
sudo apt update && sudo apt install git
```

---

## Langkah 4: Install Code Editor (VS Code)

VS Code direkomendasikan karena ringan dan punya extension Flutter yang bagus.

1. Download dari [code.visualstudio.com](https://code.visualstudio.com/)
2. Install
3. Buka VS Code → buka menu **Extensions** (Ctrl+Shift+X)
4. Install extensions berikut:
   - **Flutter** (by Dart Code)
   - **Dart** (by Dart Code)
5. Restart VS Code

> 💡 Kamu juga bisa pakai **Android Studio** sebagai editor, tapi VS Code lebih ringan.

---

## Langkah 5: Clone Project & Install Dependencies

Buka terminal/command prompt, lalu jalankan:

```bash
# 1. Clone repository
git clone https://github.com/adityadarmawann/money-planner.git

# 2. Masuk ke folder project
cd money-planner

# 3. Install semua dependencies Flutter
flutter pub get
```

Tunggu sampai proses selesai (download packages dari internet).

### Verifikasi Project

```bash
# Cek apakah project Flutter valid
flutter analyze
```

Jika tidak ada error fatal, project siap digunakan ✅

---

## Langkah 6: Setup Supabase (Backend & Database)

Supabase adalah backend gratis yang menyediakan database, autentikasi, dan API otomatis.

### 6a. Buat Akun & Project Supabase

1. Buka [supabase.com](https://supabase.com) → klik **Start your project** → Sign up (gratis)
2. Login → klik **New Project**
3. Isi:
   - **Organization**: Pilih atau buat baru
   - **Project name**: `planney`
   - **Database Password**: Buat password yang kuat (catat!)
   - **Region**: Pilih **Southeast Asia (Singapore)** untuk koneksi tercepat
4. Klik **Create new project** → Tunggu 1-2 menit sampai selesai

### 6b. Jalankan Database Schema

1. Di Supabase Dashboard, klik **SQL Editor** di sidebar kiri
2. Klik **New Query**
3. Buka file `supabase/schema.sql` dari project yang sudah di-clone
4. **Salin seluruh isi file** dan **paste** ke SQL Editor
5. Klik **Run** (atau tekan Ctrl+Enter)
6. Pastikan muncul pesan **"Success. No rows returned"** — artinya semua tabel berhasil dibuat ✅

### 6c. Catat URL & Anon Key

1. Di Supabase Dashboard, klik **Settings** (ikon gear ⚙️) di sidebar
2. Klik **API** di submenu
3. Catat 2 nilai ini:
   - **Project URL** → contoh: `https://abcdefgh.supabase.co`
   - **anon public** key → contoh: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

> ⚠️ **Simpan kedua nilai ini!** Akan dipakai di langkah berikutnya.

### 6d. Aktifkan Email Auth

1. Di sidebar, klik **Authentication** → **Providers**
2. Pastikan **Email** sudah enabled (biasanya sudah default)
3. (Opsional) Matikan **Confirm email** di **Authentication** → **Settings** jika ingin langsung bisa login tanpa verifikasi email saat development

---

## Langkah 7: Konfigurasi Environment

Agar kredensial Supabase aman dan tidak ter-commit ke GitHub, kita menggunakan file `.env`.

### 7a. Buat File .env

```bash
# Di folder project, salin template
cp .env.example .env
```

### 7b. Edit File .env

Buka file `.env` dengan text editor (VS Code / Notepad), lalu isi:

```env
SUPABASE_URL=https://abcdefgh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Ganti dengan **Project URL** dan **anon key** yang kamu catat di Langkah 6c.

> ⚠️ **Jangan pernah upload file `.env` ke GitHub!** File ini sudah otomatis di-ignore oleh `.gitignore`.

---

## Langkah 8: Setup Google Sign-In (Opsional)

> 💡 **Langkah ini opsional.** Jika kamu hanya ingin login dengan email & password, langkah ini bisa dilewati.

### 8a. Setup di Google Cloud Console

1. Buka [console.cloud.google.com](https://console.cloud.google.com)
2. Buat project baru → Beri nama "Planney"
3. Buka **APIs & Services** → **Credentials**
4. Klik **Create Credentials** → **OAuth 2.0 Client ID**
5. Application type: **Android**
6. Package name: `com.adityadarmawann.planney` (sesuaikan di `android/app/build.gradle`)
7. SHA-1 fingerprint:
   ```bash
   # Untuk debug key (development)
   # Windows:
   keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

   # macOS/Linux:
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   Salin nilai **SHA1** dan paste di Google Console
8. Klik **Create** → Catat **Client ID**

### 8b. Setup di Supabase

1. Buka Supabase Dashboard → **Authentication** → **Providers**
2. Cari **Google** → Enable
3. Masukkan **Client ID** dan **Client Secret** dari Google Console
4. Klik **Save**

### 8c. Setup Android (google-services.json)

1. Di Google Cloud Console → **Firebase Console** → buat project
2. Tambahkan app Android → Download `google-services.json`
3. Simpan file ke `android/app/google-services.json`

---

## Langkah 9: Jalankan Aplikasi (Development)

### 9a. Pastikan Device Terhubung

```bash
# Cek device yang tersedia
flutter devices
```

Harus muncul minimal satu device:
- **Emulator Android** (dari Android Studio), atau
- **HP Android** yang terhubung via USB/WiFi, atau
- **Chrome** (untuk web preview)

### 9b. Jalankan Aplikasi

```bash
# Jalankan dengan konfigurasi environment
flutter run --dart-define-from-file=.env
```

> 💡 **Pertama kali build** akan memakan waktu 2-5 menit (download Gradle, compile, dll). Build selanjutnya akan lebih cepat.

### 9c. Jika Pakai VS Code

1. Buka file `.vscode/launch.json` (sudah disediakan di project):
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Planney (Debug)",
         "request": "launch",
         "type": "dart",
         "args": [
           "--dart-define-from-file=.env"
         ]
       },
       {
         "name": "Planney (Release)",
         "request": "launch",
         "type": "dart",
         "flutterMode": "release",
         "args": [
           "--dart-define-from-file=.env"
         ]
       }
     ]
   }
   ```
2. Tekan **F5** untuk menjalankan (pilih **Planney (Debug)** dari dropdown)

### 9d. Hot Reload & Hot Restart

Saat aplikasi berjalan:
- Tekan **`r`** di terminal → **Hot Reload** (refresh UI tanpa kehilangan state)
- Tekan **`R`** di terminal → **Hot Restart** (restart penuh)
- Tekan **`q`** di terminal → Quit/berhenti

---

## Langkah 10: Test di HP Android via WiFi

Jika ingin test langsung di HP Android (tanpa emulator):

### Opsi A: Via Kabel USB (Paling Mudah)

1. Di HP Android, aktifkan **Developer Options**:
   - Buka **Settings** → **About Phone** → Tap **Build Number** 7 kali
2. Aktifkan **USB Debugging**:
   - Buka **Settings** → **Developer Options** → Aktifkan **USB Debugging**
3. Hubungkan HP ke PC dengan kabel USB
4. Di HP, ketuk **Allow/Izinkan** saat muncul pop-up USB debugging
5. Jalankan:
   ```bash
   flutter devices   # Pastikan HP terdeteksi
   flutter run --dart-define-from-file=.env
   ```

### Opsi B: Via WiFi (Wireless Debugging — Android 11+)

1. Pastikan HP dan PC terhubung ke **WiFi yang sama**
2. Di HP, aktifkan **Wireless Debugging**:
   - **Settings** → **Developer Options** → **Wireless debugging** → Aktifkan
3. Tap **Pair device with pairing code**
4. Di PC, jalankan:
   ```bash
   adb pair <IP:Port>
   # Masukkan pairing code yang muncul di HP

   adb connect <IP:Port>
   # Gunakan IP:Port dari "Wireless debugging" (bukan yang pairing)
   ```
5. Jalankan:
   ```bash
   flutter run --dart-define-from-file=.env
   ```

### Catatan untuk Supabase Self-Hosted

Jika pakai Supabase di Docker (self-hosted), gunakan **IP lokal PC** di `.env`:

```env
# Jangan pakai localhost — HP tidak mengenal localhost PC
SUPABASE_URL=http://192.168.1.100:54321
```

Cari IP PC:
```bash
# Windows
ipconfig

# macOS/Linux
ifconfig
```

> 💡 Jika pakai **Supabase Cloud** (supabase.com), tidak perlu setting khusus — langsung pakai URL `https://xxxxx.supabase.co`.

---

## Langkah 11: Build APK (File Instalasi Android)

Setelah aplikasi berjalan dengan baik di development, kamu bisa build **file APK** untuk diinstall di HP Android manapun.

### ⚠️ Penting: Flutter Menghasilkan APK, Bukan EXE

| Platform | File Output | Ekstensi |
|----------|-------------|----------|
| Android | APK / App Bundle | `.apk` / `.aab` |
| iOS | IPA | `.ipa` |
| Windows Desktop | EXE | `.exe` |

> Untuk **Android**, file yang dihasilkan adalah **`.apk`** — ini yang bisa diinstall langsung di HP Android.

### 11a. Build APK (Debug — Untuk Testing)

```bash
flutter build apk --debug --dart-define-from-file=.env
```

File output:
```
build/app/outputs/flutter-apk/app-debug.apk
```

### 11b. Build APK (Release — Untuk Distribusi)

```bash
flutter build apk --release --dart-define-from-file=.env
```

File output:
```
build/app/outputs/flutter-apk/app-release.apk
```

> 📦 File `app-release.apk` ini bisa langsung dikirim ke orang lain & diinstall di HP Android.

### 11c. Build APK Split per Arsitektur (Ukuran Lebih Kecil)

```bash
flutter build apk --split-per-abi --release --dart-define-from-file=.env
```

File output (3 file, pilih sesuai HP):
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk  → HP Android lama (32-bit)
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk    → HP Android modern (64-bit) ✅ Paling umum
build/app/outputs/flutter-apk/app-x86_64-release.apk       → Emulator/Chromebook
```

> 💡 Kebanyakan HP Android modern menggunakan **arm64-v8a**. Gunakan file ini jika ragu.

### 11d. Build App Bundle (Untuk Upload ke Play Store)

```bash
flutter build appbundle --release --dart-define-from-file=.env
```

File output:
```
build/app/outputs/bundle/release/app-release.aab
```

### 11e. Install APK ke HP

**Cara 1: Via ADB (dari PC)**
```bash
# Pastikan HP terhubung via USB atau WiFi debugging
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Cara 2: Transfer Manual**
1. Kirim file `.apk` ke HP (via WhatsApp, Email, Google Drive, Bluetooth, kabel USB)
2. Buka file `.apk` di HP
3. Jika muncul peringatan "Install from unknown sources" → Izinkan
4. Tap **Install**
5. Selesai! Buka aplikasi **Planney** 🎉

---

## 📁 Struktur Folder

```
money-planner/
├── .env.example                      # Template konfigurasi (SALIN jadi .env)
├── .gitignore                        # File yang di-ignore Git
├── pubspec.yaml                      # Dependencies Flutter
├── README.md                         # File yang kamu baca sekarang
├── supabase/
│   └── schema.sql                    # Database DDL (jalankan di Supabase SQL Editor)
├── android/                          # Konfigurasi native Android
├── ios/                              # Konfigurasi native iOS
└── lib/                              # Source code Dart/Flutter
    ├── main.dart                     # Entry point aplikasi
    ├── app.dart                      # MaterialApp + routing
    ├── core/
    │   ├── config/
    │   │   └── env_config.dart       # Baca konfigurasi dari environment
    │   ├── constants/
    │   │   ├── app_colors.dart       # Warna tema (putih + biru muda)
    │   │   ├── app_strings.dart      # String UI bahasa Indonesia
    │   │   └── app_routes.dart       # Nama routes navigasi
    │   ├── theme/
    │   │   └── app_theme.dart        # Tema Material Design
    │   ├── utils/
    │   │   ├── currency_formatter.dart  # Format Rp 1.000.000
    │   │   ├── date_formatter.dart      # Format tanggal Indonesia
    │   │   └── validators.dart          # Validasi input form
    │   └── errors/
    │       └── app_exception.dart    # Custom error handling
    ├── data/
    │   ├── models/                   # 8 model data (user, wallet, transaction, dll)
    │   └── repositories/            # 6 repository (CRUD ke Supabase)
    ├── providers/                    # 6 provider (state management)
    └── presentation/
        ├── screens/                  # 20+ layar aplikasi
        └── widgets/                  # Widget reusable (button, card, chart, dll)
```

---

## 🗄 Database Schema

Semua tabel database ada di file `supabase/schema.sql`.

| Tabel | Keterangan |
|-------|------------|
| `users` | Profil pengguna (nama, email, avatar, phone) |
| `wallets` | Saldo e-wallet per user (dalam Rupiah) |
| `categories` | Kategori income/expense (Beasiswa, Makan, Transport, dll) |
| `transactions` | Riwayat semua transaksi (topup, transfer, paylater, dll) |
| `paylater_accounts` | Akun paylater (limit Rp 1.000.000, bunga 2.5%/bulan) |
| `paylater_bills` | Tagihan paylater (tenor, due date, status) |
| `budgets` | Anggaran keuangan (weekly/monthly/custom) |
| `budget_items` | Item per anggaran (per kategori & tanggal) |

---

## 🔧 Troubleshooting

### ❌ `flutter: command not found`
Flutter belum ditambahkan ke PATH. Ulangi Langkah 1.

### ❌ `No devices found`
- Pastikan emulator Android berjalan, ATAU
- Pastikan HP Android terhubung dengan USB debugging aktif
- Jalankan `flutter devices` untuk cek

### ❌ `Gradle build failed`
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run --dart-define-from-file=.env
```

### ❌ `Konfigurasi Belum Lengkap` (muncul di app)
File `.env` belum dibuat atau belum diisi. Ulangi Langkah 7.

### ❌ `SocketException: Connection refused`
- Jika pakai Supabase self-hosted: pastikan Docker berjalan
- Pastikan URL di `.env` benar (gunakan IP lokal, bukan `localhost`, jika test di HP)
- Pastikan HP dan PC di WiFi yang sama

### ❌ `PlatformException` saat Google Sign-In
- Pastikan SHA-1 fingerprint sudah ditambahkan di Google Console
- Pastikan `google-services.json` ada di `android/app/`
- Pastikan Google provider sudah di-enable di Supabase Dashboard

### ❌ APK tidak bisa diinstall di HP
- Aktifkan "Install from unknown sources" di Settings HP
- Pastikan HP mendukung arsitektur yang benar (arm64-v8a untuk HP modern)

---

## 📝 Ringkasan Urutan Lengkap

```
1. Install Flutter SDK          → flutter --version
2. Install Android Studio       → Buat emulator
3. Install Git                  → git --version
4. Clone project                → git clone ... && cd money-planner
5. Install dependencies         → flutter pub get
6. Buat Supabase project        → Catat URL & Anon Key
7. Jalankan schema.sql          → Di Supabase SQL Editor
8. Buat file .env               → Isi URL & Key
9. Jalankan app (development)   → flutter run --dart-define-from-file=.env
10. Build APK (release)         → flutter build apk --release --dart-define-from-file=.env
11. Install APK di HP           → Transfer & install file .apk
```

---

## 📄 Lisensi

MIT — Bebas digunakan untuk keperluan apapun.

---

**Dibuat dengan ❤️ untuk mahasiswa Indonesia 🇮🇩**
