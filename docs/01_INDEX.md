# 📖 Planney - Dokumentasi Index

> Portal utama untuk semua dokumentasi Planney

---

## 🗂️ Daftar Dokumentasi

### 🚀 Untuk Pemula & Setup

| Dokumen | Deskripsi | Waktu Baca |
|---------|-----------|------------|
| **[README.md](../README.md)** | Setup awal, instalasi, cara menjalankan aplikasi | 15 menit |

### 👨‍💻 Untuk Developer

| Dokumen | Deskripsi | Target Audience | Waktu Baca |
|---------|-----------|-----------------|------------|
| **[02_DEVELOPER_GUIDE.md](02_DEVELOPER_GUIDE.md)** | Panduan lengkap developer - arsitektur, struktur folder, lokasi file setiap fitur, cara edit & tambah fitur | Developer baru yang ingin modify source code | 30-45 menit |
| **[03_QUICK_REFERENCE.md](03_QUICK_REFERENCE.md)** | Cheat sheet - referensi cepat lokasi file, commands, dan common tasks | Developer yang sudah familiar dengan codebase | 5-10 menit |
| **[04_ARCHITECTURE.md](04_ARCHITECTURE.md)** | Diagram alur & flow chart setiap fitur, arsitektur visual | Developer yang ingin memahami big picture, atau untuk mengajar orang lain | 20-30 menit |

### � Appendix - Dokumentasi Spesifik Fitur

| Dokumen | Deskripsi |
|---------|-----------|
| **[appendix/PAYLATER_IMPLEMENTATION.md](appendix/PAYLATER_IMPLEMENTATION.md)** | Detail implementasi fitur Paylater |
| **[appendix/CALENDAR_INTEGRATION.md](appendix/CALENDAR_INTEGRATION.md)** | Integrasi dengan device calendar |

---

## 🎯 Panduan Memilih Dokumentasi

### "Saya baru pertama kali lihat project ini, mulai dari mana?"

1. ✅ **[README.md](../README.md)** - Setup & run aplikasi dulu
2. ✅ **[04_ARCHITECTURE.md](04_ARCHITECTURE.md)** - Lihat big picture & flow diagram
3. ✅ **[02_DEVELOPER_GUIDE.md](02_DEVELOPER_GUIDE.md)** - Pelajari struktur & cara kerja

### "Saya mau edit fitur tertentu, file nya dimana?"

✅ **[03_QUICK_REFERENCE.md](03_QUICK_REFERENCE.md)** - Langsung cek lokasi file

### "Saya mau ngajarin orang lain tentang aplikasi ini"

✅ **[04_ARCHITECTURE.md](04_ARCHITECTURE.md)** - Gunakan diagram flow untuk explain

### "Saya developer, mau tahu semua detail teknis"

✅ **[02_DEVELOPER_GUIDE.md](02_DEVELOPER_GUIDE.md)** - Baca lengkap dari awal sampai akhir

### "Saya mau tau cara kerja Paylater / Calendar"

✅ Lihat documentasi spesifik: 
- [appendix/PAYLATER_IMPLEMENTATION.md](appendix/PAYLATER_IMPLEMENTATION.md)
- [appendix/CALENDAR_INTEGRATION.md](appendix/CALENDAR_INTEGRATION.md)

---

## 📚 Quick Links ke Section Penting

### Lokasi File Fitur

| Fitur | Lokasi di Dokumentasi |
|-------|----------------------|
| **Beranda** | [02_DEVELOPER_GUIDE.md § Beranda](02_DEVELOPER_GUIDE.md#1-beranda-home-screen) |
| **Transfer** | [02_DEVELOPER_GUIDE.md § Transfer](02_DEVELOPER_GUIDE.md#2-transfer) |
| **Top Up** | [02_DEVELOPER_GUIDE.md § Top Up](02_DEVELOPER_GUIDE.md#4-top-up-e-wallet) |
| **Paylater** | [02_DEVELOPER_GUIDE.md § Paylater](02_DEVELOPER_GUIDE.md#5-paylater) |
| **Budget/MyPlan** | [02_DEVELOPER_GUIDE.md § Budget](02_DEVELOPER_GUIDE.md#6-budget--my-plan-anggaran) |
| **QRIS** | [02_DEVELOPER_GUIDE.md § QRIS](02_DEVELOPER_GUIDE.md#3-qris) |
| **Expense Plans** | [02_DEVELOPER_GUIDE.md § Expense Plans](02_DEVELOPER_GUIDE.md#7-rencana-pengeluaran-expense-plans) |

### Flow Diagrams

| Flow | Lokasi di Dokumentasi |
|------|----------------------|
| **Login Flow** | [04_ARCHITECTURE.md § Login](04_ARCHITECTURE.md#-flow-diagram-login) |
| **Transfer Flow** | [04_ARCHITECTURE.md § Transfer](04_ARCHITECTURE.md#-flow-diagram-transfer) |
| **Top Up Flow** | [04_ARCHITECTURE.md § Top Up](04_ARCHITECTURE.md#-flow-diagram-top-up) |
| **Paylater Flow** | [04_ARCHITECTURE.md § Paylater](04_ARCHITECTURE.md#-flow-diagram-paylater) |
| **Budget Flow** | [04_ARCHITECTURE.md § Budget](04_ARCHITECTURE.md#-flow-diagram-budget-myplan) |
| **State Management** | [04_ARCHITECTURE.md § State Management](04_ARCHITECTURE.md#-state-management-flow-provider-pattern) |

### Common Tasks

| Task | Lokasi di Dokumentasi |
|------|----------------------|
| **Ubah Warna** | [03_QUICK_REFERENCE.md § Warna](03_QUICK_REFERENCE.md#warna) |
| **Tambah Screen** | [02_DEVELOPER_GUIDE.md § Tambah Screen](02_DEVELOPER_GUIDE.md#1-menambah-screen-baru) |
| **Tambah Widget** | [02_DEVELOPER_GUIDE.md § Tambah Widget](02_DEVELOPER_GUIDE.md#2-menambah-widget-reusable) |
| **Tambah Provider** | [02_DEVELOPER_GUIDE.md § Tambah Provider](02_DEVELOPER_GUIDE.md#5-menambah-provider-state-management) |
| **Query Supabase** | [02_DEVELOPER_GUIDE.md § Supabase](02_DEVELOPER_GUIDE.md#cara-query-supabase) |

---

## 🔍 Search Tips

Gunakan <kbd>Ctrl</kbd>+<kbd>F</kbd> (Windows) atau <kbd>Cmd</kbd>+<kbd>F</kbd> (Mac) untuk search di dokumentasi:

**Contoh keyword search:**
- `transfer` - Cari semua yang berkaitan dengan transfer
- `lib/presentation/screens` - Cari lokasi screens
- `Provider` - Cari tentang state management
- `Supabase` - Cari tentang database operations
- `fl_chart` - Cari tentang charts/graphs

---

## 📞 Butuh Bantuan?

1. **Cek dokumentasi terlebih dahulu** (90% pertanyaan ada di sini)
2. **Baca code comments** di file-file penting
3. **Lihat contoh implementasi** yang sudah ada
4. **Google/Stack Overflow** untuk error message
5. **Flutter Documentation** untuk widget/package tertentu

---

## 🎓 Learning Path

Untuk developer baru yang ingin belajar:

```
Day 1-2: Setup & Familiarization
├─ Baca README.md
├─ Install & run aplikasi
├─ Explore UI aplikasi
└─ Lihat ARCHITECTURE.md (diagram)

Day 3-5: Code Reading
├─ Baca DEVELOPER_GUIDE.md
├─ Explore struktur folder
├─ Baca code di lib/presentation/screens/home/
└─ Pahami flow 1 fitur (misal: Top Up)

Day 6-10: Hands-on Practice
├─ Ubah warna aplikasi
├─ Ubah teks di screen
├─ Tambah widget sederhana
└─ Modify existing feature

Day 11-15: Build New Feature
├─ Design feature kecil
├─ Buat screen baru
├─ Tambah provider & repository
├─ Connect to Supabase
└─ Testing

Day 16+: Advanced Topics
├─ Optimasi performance
├─ Error handling
├─ Testing
└─ Deployment
```

---

## 📝 Contribution Guidelines

Jika ingin update dokumentasi:

1. **Keep it simple** - Bahasa yang mudah dipahami
2. **Add examples** - Code examples sangat membantu
3. **Update all docs** - Jika ada perubahan besar, update semua dokumen terkait
4. **Use consistent format** - Ikuti format yang sudah ada

---

## 📊 Dokumentasi Statistics

| Metric | Value |
|--------|-------|
| Total Documentation Files | 11+ |
| Total Lines of Documentation | ~3000+ |
| Code Examples | 50+ |
| Flow Diagrams | 10+ |
| Last Updated | March 5, 2026 |

---

**Selamat belajar & coding! 🚀**

Jika ada pertanyaan atau saran untuk dokumentasi, feel free to update atau request.

