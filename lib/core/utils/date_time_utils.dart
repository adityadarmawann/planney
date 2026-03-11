class DateTimeUtils {
  DateTimeUtils._();

  static String toUtcIsoString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  static String? toUtcIsoStringOrNull(DateTime? dateTime) {
    return dateTime == null ? null : toUtcIsoString(dateTime);
  }

  static String toLocalDateOnlyString(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}