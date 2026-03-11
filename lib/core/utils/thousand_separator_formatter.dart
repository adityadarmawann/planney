import 'package:flutter/services.dart';

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Extract only digits
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format with thousand separator (dot)
    final formatted = _formatWithDots(digits);

    // Calculate cursor position
    int cursorPosition = formatted.length;
    if (oldValue.text.isNotEmpty && 
        digits.length >= oldValue.text.replaceAll(RegExp(r'[^0-9]'), '').length) {
      // Cursor should be at the end of new formatted text
      cursorPosition = formatted.length;
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  String _formatWithDots(String digits) {
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
