import '../../core/utils/date_time_utils.dart';

enum TransactionType {
  topup,
  transferIn,
  transferOut,
  bankTransfer,
  qrisPayment,
  qrisPaylater,
  paylaterDisbursement,
  paylaterPayment,
  withdrawal,
}

enum TransactionStatus { pending, success, failed, cancelled }

class TransactionModel {
  final String id;
  final String? senderId;
  final String? receiverId;
  final String walletId;
  final TransactionType type;
  final double amount;
  final double fee;
  final TransactionStatus status;
  final String? note;
  final String refCode;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    this.senderId,
    this.receiverId,
    required this.walletId,
    required this.type,
    required this.amount,
    this.fee = 0,
    this.status = TransactionStatus.success,
    this.note,
    required this.refCode,
    this.metadata,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>?;
    return TransactionModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      walletId: json['wallet_id'] as String,
      type: _parseType(json['type'] as String, metadata),
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num? ?? 0).toDouble(),
      status: _parseStatus(json['status'] as String? ?? 'success'),
      note: json['note'] as String?,
      refCode: json['ref_code'] as String,
      metadata: metadata,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static TransactionType _parseType(
    String value,
    Map<String, dynamic>? metadata,
  ) {
    final paymentMethod = metadata?['payment_method'];
    switch (value) {
      case 'topup':
        return TransactionType.topup;
      case 'transfer_in':
        return TransactionType.transferIn;
      case 'transfer_out':
        return TransactionType.transferOut;
      case 'bank_transfer':
        if (paymentMethod == 'qris') {
          return TransactionType.qrisPayment;
        }
        return TransactionType.bankTransfer;
      case 'qris_payment':
        return TransactionType.qrisPayment;
      case 'qris_paylater':
        return TransactionType.qrisPaylater;
      case 'paylater_disbursement':
        return TransactionType.paylaterDisbursement;
      case 'paylater_payment':
        return TransactionType.paylaterPayment;
      case 'withdrawal':
        return TransactionType.withdrawal;
      default:
        return TransactionType.topup;
    }
  }

  static TransactionStatus _parseStatus(String value) {
    switch (value) {
      case 'pending':
        return TransactionStatus.pending;
      case 'success':
        return TransactionStatus.success;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.success;
    }
  }

  String get typeString {
    switch (type) {
      case TransactionType.topup:
        return 'topup';
      case TransactionType.transferIn:
        return 'transfer_in';
      case TransactionType.transferOut:
        return 'transfer_out';
      case TransactionType.bankTransfer:
        return 'bank_transfer';
      case TransactionType.qrisPayment:
        return 'qris_payment';
      case TransactionType.qrisPaylater:
        return 'qris_paylater';
      case TransactionType.paylaterDisbursement:
        return 'paylater_disbursement';
      case TransactionType.paylaterPayment:
        return 'paylater_payment';
      case TransactionType.withdrawal:
        return 'withdrawal';
    }
  }

  String get typeLabel {
    switch (type) {
      case TransactionType.topup:
        return 'Top Up';
      case TransactionType.transferIn:
        return 'Transfer Masuk';
      case TransactionType.transferOut:
        return 'Transfer Keluar';
      case TransactionType.bankTransfer:
        return 'Transfer Bank';
      case TransactionType.qrisPayment:
        return 'Pembayaran QRIS';
      case TransactionType.qrisPaylater:
        return 'QRIS via PayLater';
      case TransactionType.paylaterDisbursement:
        return 'Cairkan Paylater';
      case TransactionType.paylaterPayment:
        return 'Bayar Paylater';
      case TransactionType.withdrawal:
        return 'Penarikan';
    }
  }

  String? get merchantName {
    final merchant = metadata?['merchant_name'];
    return merchant is String && merchant.trim().isNotEmpty ? merchant.trim() : null;
  }

  bool get isCredit {
    return type == TransactionType.topup ||
        type == TransactionType.transferIn ||
        type == TransactionType.paylaterDisbursement;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'wallet_id': walletId,
      'type': typeString,
      'amount': amount,
      'fee': fee,
      'status': status.name,
      'note': note,
      'ref_code': refCode,
      'metadata': metadata,
      'created_at': DateTimeUtils.toUtcIsoString(createdAt),
    };
  }
}
