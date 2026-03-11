enum PaylaterStatus { active, suspended, closed }

class PaylaterAccountModel {
  final String id;
  final String userId;
  final double creditLimit;
  final double usedLimit;
  final double interestRate;
  final PaylaterStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Auto-increase limit tracking
  final int onTimePaymentCount;
  final int totalPaidBills;
  final int latePaymentCount;
  final DateTime? lastLimitIncrease;
  final DateTime? nextLimitReviewDate;

  const PaylaterAccountModel({
    required this.id,
    required this.userId,
    this.creditLimit = 2500000,  // Default 2.5jt
    this.usedLimit = 0,
    this.interestRate = 2.5,
    this.status = PaylaterStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.onTimePaymentCount = 0,
    this.totalPaidBills = 0,
    this.latePaymentCount = 0,
    this.lastLimitIncrease,
    this.nextLimitReviewDate,
  });

  double get remainingLimit => creditLimit - usedLimit;

  double get usedPercentage =>
      creditLimit > 0 ? (usedLimit / creditLimit * 100).clamp(0, 100) : 0;
  
  // Progress untuk kenaikan limit berikutnya (0-3)
  int get nextIncreaseProgress => onTimePaymentCount % 3;
  
  // Sisa pembayaran tepat waktu yang dibutuhkan (3 - progress)
  int get paymentsNeededForIncrease => 3 - nextIncreaseProgress;
  
  // Apakah sudah mencapai limit maksimal
  bool get isMaxLimit => creditLimit >= 10000000;
  
  // Apakah eligible untuk review kenaikan limit
  bool get canReviewLimitIncrease {
    if (isMaxLimit || onTimePaymentCount < 3) return false;
    if (nextLimitReviewDate == null) return true;
    return DateTime.now().isAfter(nextLimitReviewDate!);
  }

  factory PaylaterAccountModel.fromJson(Map<String, dynamic> json) {
    return PaylaterAccountModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      creditLimit: (json['credit_limit'] as num? ?? 2500000).toDouble(),
      usedLimit: (json['used_limit'] as num? ?? 0).toDouble(),
      interestRate: (json['interest_rate'] as num? ?? 2.5).toDouble(),
      status: _parseStatus(json['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      onTimePaymentCount: json['on_time_payment_count'] as int? ?? 0,
      totalPaidBills: json['total_paid_bills'] as int? ?? 0,
      latePaymentCount: json['late_payment_count'] as int? ?? 0,
      lastLimitIncrease: json['last_limit_increase'] != null
          ? DateTime.parse(json['last_limit_increase'] as String)
          : null,
      nextLimitReviewDate: json['next_limit_review_date'] != null
          ? DateTime.parse(json['next_limit_review_date'] as String)
          : null,
    );
  }

  static PaylaterStatus _parseStatus(String value) {
    switch (value) {
      case 'suspended':
        return PaylaterStatus.suspended;
      case 'closed':
        return PaylaterStatus.closed;
      default:
        return PaylaterStatus.active;
    }
  }

  PaylaterAccountModel copyWith({
    String? id,
    String? userId,
    double? creditLimit,
    double? usedLimit,
    double? interestRate,
    PaylaterStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? onTimePaymentCount,
    int? totalPaidBills,
    int? latePaymentCount,
    DateTime? lastLimitIncrease,
    DateTime? nextLimitReviewDate,
  }) {
    return PaylaterAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      creditLimit: creditLimit ?? this.creditLimit,
      usedLimit: usedLimit ?? this.usedLimit,
      interestRate: interestRate ?? this.interestRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      onTimePaymentCount: onTimePaymentCount ?? this.onTimePaymentCount,
      totalPaidBills: totalPaidBills ?? this.totalPaidBills,
      latePaymentCount: latePaymentCount ?? this.latePaymentCount,
      lastLimitIncrease: lastLimitIncrease ?? this.lastLimitIncrease,
      nextLimitReviewDate: nextLimitReviewDate ?? this.nextLimitReviewDate,
    );
  }
}
