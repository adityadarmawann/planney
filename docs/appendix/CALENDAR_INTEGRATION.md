# Device Calendar Integration untuk Rencana Pengeluaran

## ✨ Fitur Baru: Sinkronisasi Otomatis ke Calendar Device

Rencana pengeluaran sekarang otomatis tersinkronisasi ke aplikasi Calendar bawaan device (Google Calendar di Android, Apple Calendar di iOS).

---

## 📱 Cara Menggunakan

### 1. **Izin Permission**
Pertama kali membuat rencana pengeluaran, aplikasi akan meminta izin akses calendar:
- **Android**: Izinkan akses "Calendar" dan "Storage"
- **iOS**: Izinkan akses "Calendars" dan "Reminders"

### 2. **Membuat Rencana Pengeluaran**
Saat membuat rencana pengeluaran baru, otomatis akan:
- ✅ Ditambahkan ke calendar device dengan prefix 💸
- ✅ Include semua detail (jumlah, kategori, sumber pembayaran, catatan)
- ✅ Set reminder sesuai pilihan:
  - **H-1**: Reminder 1 hari sebelumnya
  - **H-3**: Reminder 3 hari sebelumnya
  - **Custom**: Sesuai jam yang ditentukan

### 3. **Event Format di Calendar**
```
Title: 💸 [Nama Rencana]
Date: [Tanggal Rencana]
Time: 09:00 - 10:00 (default)

Description:
Kategori: [Kategori]
Jumlah: Rp [Amount]
Sumber Pembayaran: [PaymentSource]

Catatan:
[Notes jika ada]

📱 Dibuat dari Planney App
```

### 4. **Update & Delete**
- **Update**: Saat edit rencana, event di calendar juga terupdate
- **Delete**: Saat hapus rencana, event di calendar juga terhapus

---

## 🔧 Setup Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Build APK/Run
```bash
# Development
flutter run

# Release
flutter build apk --release --dart-define-from-file=.env
```

### Step 3: Permission Handling
Aplikasi akan otomatis request permission saat pertama kali digunakan.

---

## 🎯 Keuntungan Sinkronisasi Calendar

1. **Terlihat di Semua Device**
   - Rencana pengeluaran muncul di semua device yang tersinkronisasi dengan akun Google/Apple kamu

2. **Notifikasi Native**
   - Reminder menggunakan sistem notifikasi device (lebih reliable)

3. **Integrasi dengan Apps Lain**
   - Rencana pengeluaran bisa dilihat dari Google Calendar web, widget calendar, dll

4. **Backup Otomatis**
   - Event tersimpan di cloud (Google/Apple)

---

## 🛠️ Troubleshooting

### Permission Denied
**Solusi**: 
1. Buka **Settings** → **Apps** → **Planney**
2. Ke **Permissions**
3. Enable **Calendar** permission

### Event Tidak Muncul
**Solusi**:
1. Pastikan permission sudah granted
2. Buka aplikasi Calendar native → Refresh
3. Check apakah calendar "Planney - Rencana Pengeluaran" aktif

### Duplicate Events
**Solusi**:
- Aplikasi menggunakan ID unik untuk setiap event
- Jika terjadi duplikasi, hapus manual di Calendar atau reinstall app

---

## 📋 Technical Details

### Dependencies Added
```yaml
device_calendar: ^4.3.3          # Device calendar integration
permission_handler: ^11.3.1      # Permission management
timezone: ^0.9.4                 # Timezone handling
```

### Permissions Added

**Android** (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.READ_CALENDAR"/>
<uses-permission android:name="android.permission.WRITE_CALENDAR"/>
```

**iOS** (`Info.plist`):
```xml
<key>NSCalendarsUsageDescription</key>
<string>Aplikasi membutuhkan akses kalender untuk menambahkan reminder rencana pengeluaran</string>
<key>NSRemindersUsageDescription</key>
<string>Aplikasi membutuhkan akses reminder untuk notifikasi rencana pengeluaran</string>
```

### Files Modified
- `lib/core/services/calendar_service.dart` - New service for calendar sync
- `lib/providers/expense_plan_provider.dart` - Added auto-sync on create/update/delete
- `android/app/src/main/AndroidManifest.xml` - Added calendar permissions
- `ios/Runner/Info.plist` - Added calendar usage descriptions
- `pubspec.yaml` - Added dependencies

---

## ⚙️ Configuration

### Timezone
Default timezone: **Asia/Jakarta** (WIB)

Jika perlu mengubah, edit di `lib/core/services/calendar_service.dart`:
```dart
static final local = getLocation('Asia/Jakarta'); // Ganti sesuai timezone
```

### Event Time
Default event time: **09:00 - 10:00**

Jika perlu mengubah, edit di `lib/core/services/calendar_service.dart` method `syncExpensePlanToCalendar()`.

---

## 🚀 Ready to Use!

Setelah `flutter pub get`, fitur sinkronisasi calendar sudah aktif dan akan bekerja otomatis setiap kali:
- ✅ Membuat rencana pengeluaran baru
- ✅ Update rencana pengeluaran
- ✅ Hapus rencana pengeluaran

**Tidak perlu konfigurasi tambahan!** 🎉

