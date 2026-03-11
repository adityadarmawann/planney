import '../../core/utils/date_time_utils.dart';

enum BillStatus { active, paid, overdue, cancelled }

class PaylaterBillModel {
  final String id;
  final String paylaterId;
  final String userId;
  final double principalAmount;
  final double interestAmount;
  final double lateFeeAmount;
  final double totalDue;
  final int tenorMonths;
  final DateTime dueDate;
  final DateTime? paidAt;
  final BillStatus status;
  final String? transactionId;
  final DateTime createdAt;

  const PaylaterBillModel({
    required this.id,
    required this.paylaterId,
    required this.userId,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalDue,
    required this.tenorMonths,
    required this.dueDate,
    this.paidAt,
    this.lateFeeAmount = 0.0,
    this.status = BillStatus.active,
    this.transactionId,
    required this.createdAt,
  });

  bool get isOverdue =>
      status == BillStatus.active && dueDate.isBefore(DateTime.now());

  /// Calculate late fee based on days overdue (Shopee referral)
  /// 0-7 days: 0%, 8-14 days: 2.5%, 15-30 days: 5%, 30+ days: 10%
  double _calculateLateFee() {
    if (status == BillStatus.paid || !isOverdue) return 0.0;

    final now = DateTime.now();
    final daysOverdue = now.difference(dueDate).inDays;

    if (daysOverdue <= 7) return 0.0;
    if (daysOverdue <= 14) return principalAmount * 0.025;
    if (daysOverdue <= 30) return principalAmount * 0.05;
    return principalAmount * 0.10;
  }

  /// Get total amount due including late fee if overdue
  double get totalAmountDue {
    if (status == BillStatus.paid) return totalDue;
    return totalDue + _calculateLateFee();
  }

  factory PaylaterBillModel.fromJson(Map<String, dynamic> json) {
    return PaylaterBillModel(
      id: json['id'] as String,
      paylaterId: json['paylater_id'] as String,
      userId: json['user_id'] as String,
      principalAmount: (json['principal_amount'] as num).toDouble(),
      interestAmount: (json['interest_amount'] as num).toDouble(),
      lateFeeAmount: (json['late_fee_amount'] as num?)?.toDouble() ?? 0.0,
      totalDue: (json['total_due'] as num).toDouble(),
      tenorMonths: json['tenor_months'] as int,
      dueDate: DateTime.parse(json['due_date'] as String),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      status: _parseStatus(json['status'] as String? ?? 'active'),
      transactionId: json['transaction_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static BillStatus _parseStatus(String value) {
    switch (value) {
      case 'paid':
        return BillStatus.paid;
      case 'overdue':
        return BillStatus.overdue;
      case 'cancelled':
        return BillStatus.cancelled;
      default:
        return BillStatus.active;
    }
  }

  BillStatus get effectiveStatus {
    if (status == BillStatus.active && isOverdue) return BillStatus.overdue;
    return status;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paylater_id': paylaterId,
      'user_id': userId,
      'principal_amount': principalAmount,
      'interest_amount': interestAmount,
      'late_fee_amount': lateFeeAmount,
      'total_due': totalDue,
      'tenor_months': tenorMonths,
      'due_date': DateTimeUtils.toLocalDateOnlyString(dueDate),
      'paid_at': DateTimeUtils.toUtcIsoStringOrNull(paidAt),
      'status': status.name,
      'transaction_id': transactionId,
      'created_at': DateTimeUtils.toUtcIsoString(createdAt),
    };
  }
}
