/// Kelas untuk membaca konfigurasi dari environment variables (--dart-define).
///
/// Cara penggunaan saat menjalankan aplikasi:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
/// ```
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Validasi bahwa semua environment variables sudah di-set
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Pesan error jika konfigurasi belum di-set
  static String get configErrorMessage =>
      'Konfigurasi Supabase belum di-set!\n\n'
      'Jalankan aplikasi dengan:\n'
      'flutter run \\\n'
      '  --dart-define=SUPABASE_URL=your_url \\\n'
      '  --dart-define=SUPABASE_ANON_KEY=your_key\n\n'
      'Atau buat file .env dan gunakan --dart-define-from-file=.env';
}
