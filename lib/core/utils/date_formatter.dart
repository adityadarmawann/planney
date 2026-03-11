import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  // Use lazy getters instead of static final to ensure locale is initialized
  static DateFormat get _dateFormat => DateFormat('dd MMM yyyy', 'id_ID');
  static DateFormat get _dateTimeFormat =>
      DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static DateFormat get _timeFormat => DateFormat('HH:mm', 'id_ID');
  static DateFormat get _shortDateFormat => DateFormat('dd/MM/yyyy');
  static DateFormat get _monthYearFormat => DateFormat('MMMM yyyy', 'id_ID');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date.toLocal());
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date.toLocal());
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date.toLocal());
  }

  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date.toLocal());
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date.toLocal());
  }

  static String formatRelative(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localDate);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} menit lalu';
      }
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    }
    return formatDate(date);
  }

  static DateTime parseDate(String value) {
    return DateTime.parse(value);
  }
}
