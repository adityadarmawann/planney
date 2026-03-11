import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}Mlr';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(1)}rb';
    }
    return format(amount);
  }

  static double parse(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  static String formatAsPlainText(double amount) {
    final digits = amount.toStringAsFixed(0);
    if (digits.isEmpty) return '';
    
    // Reverse to process from right to left
    final reversed = digits.split('').reversed.join('');
    final buffer = StringBuffer();
    
    // Add dots every 3 digits, avoiding leading dot
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(reversed[i]);
    }
    
    // Reverse back to original direction
    final formatted = buffer.toString().split('').reversed.join('');
    return formatted;
  }
}
