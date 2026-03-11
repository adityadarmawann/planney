import '../../core/utils/date_time_utils.dart';

class ExpensePlan {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final DateTime plannedDate;
  final String plannedTime; // HH:mm
  final String category;
  final String paymentSource;
  final String? reminderType; // 'h-1', 'h-3', 'custom', or null
  final int? customReminderMinutes; // Preferred field for custom reminder
  final int? customReminderHours; // Legacy fallback from old schema
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpensePlan({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.plannedDate,
    this.plannedTime = '09:00',
    required this.category,
    required this.paymentSource,
    this.reminderType,
    this.customReminderMinutes,
    this.customReminderHours,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime get plannedDateTime {
    final parts = plannedTime.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(
      plannedDate.year,
      plannedDate.month,
      plannedDate.day,
      hour,
      minute,
    );
  }

  int? get effectiveCustomReminderMinutes {
    if (customReminderMinutes != null) return customReminderMinutes;
    if (customReminderHours != null) return customReminderHours! * 60;
    return null;
  }

  factory ExpensePlan.fromJson(Map<String, dynamic> json) {
    return ExpensePlan(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      plannedDate: DateTime.parse(json['planned_date']),
      plannedTime: _normalizePlannedTime(
        (json['planned_time'] ?? '09:00').toString(),
      ),
      category: json['category'],
      paymentSource: json['payment_source'],
      reminderType: json['reminder_type'],
      customReminderMinutes: (json['custom_reminder_minutes'] as num?)?.toInt(),
      customReminderHours: (json['custom_reminder_hours'] as num?)?.toInt(),
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'planned_date': DateTimeUtils.toLocalDateOnlyString(plannedDate),
      'planned_time': plannedTime,
      'category': category,
      'payment_source': paymentSource,
      'reminder_type': reminderType,
      'custom_reminder_minutes': customReminderMinutes,
      'custom_reminder_hours': customReminderHours,
      'is_completed': isCompleted,
      'completed_at': DateTimeUtils.toUtcIsoStringOrNull(completedAt),
      'notes': notes,
      'created_at': DateTimeUtils.toUtcIsoString(createdAt),
      'updated_at': DateTimeUtils.toUtcIsoString(updatedAt),
    };
  }

  ExpensePlan copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    DateTime? plannedDate,
    String? plannedTime,
    String? category,
    String? paymentSource,
    String? reminderType,
    int? customReminderMinutes,
    int? customReminderHours,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpensePlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      plannedDate: plannedDate ?? this.plannedDate,
      plannedTime: plannedTime ?? this.plannedTime,
      category: category ?? this.category,
      paymentSource: paymentSource ?? this.paymentSource,
      reminderType: reminderType ?? this.reminderType,
      customReminderMinutes: customReminderMinutes ?? this.customReminderMinutes,
      customReminderHours: customReminderHours ?? this.customReminderHours,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _normalizePlannedTime(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '09:00';
    final hhmm = raw.length >= 5 ? raw.substring(0, 5) : raw;
    final parts = hhmm.split(':');
    if (parts.length != 2) return '09:00';
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return '09:00';
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return '09:00';
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

// Constants untuk kategori
class ExpenseCategory {
  static const kosmetik = 'Kosmetik';
  static const makanan = 'Makanan & Minuman';
  static const elektronik = 'Alat Elektronik';
  static const pakaian = 'Pakaian';
  static const transportasi = 'Transportasi';
  static const hiburan = 'Hiburan';
  static const kesehatan = 'Kesehatan';
  static const pendidikan = 'Pendidikan';
  static const custom = 'Custom';

  static List<String> get defaults => [
    kosmetik,
    makanan,
    elektronik,
    pakaian,
    transportasi,
    hiburan,
    kesehatan,
    pendidikan,
  ];
}

// Constants untuk payment source
class PaymentSource {
  static const planneyWallet = 'Planney Wallet';
  static const bank = 'Bank';
  static const custom = 'Custom';

  static List<String> get defaults => [planneyWallet, bank, custom];
}

// Constants untuk reminder
class ReminderType {
  static const h1 = 'h-1'; // 1 hari sebelumnya
  static const h3 = 'h-3'; // 3 jam sebelumnya
  static const custom = 'custom';

  static Map<String, String> get labels => {
    h1: '1 Hari Sebelumnya',
    h3: '3 Jam Sebelumnya',
    custom: 'Custom (jam:menit)',
  };
}
