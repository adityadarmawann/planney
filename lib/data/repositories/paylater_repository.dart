import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paylater_account_model.dart';
import '../models/paylater_bill_model.dart';
import '../models/transaction_model.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/date_time_utils.dart';
import 'wallet_repository.dart';

class PaylaterRepository {
  final SupabaseClient _client;
  final WalletRepository _walletRepository;

  PaylaterRepository({
    required SupabaseClient client,
    required WalletRepository walletRepository,
  })  : _client = client,
        _walletRepository = walletRepository;

  Future<PaylaterAccountModel?> getAccount(String userId) async {
    try {
      final data = await _client
          .from('paylater_accounts')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return PaylaterAccountModel.fromJson(data);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<List<PaylaterBillModel>> getBills(String userId) async {
    try {
      final data = await _client
          .from('paylater_bills')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => PaylaterBillModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<PaylaterBillModel?> getBillById(String id) async {
    try {
      final data = await _client
          .from('paylater_bills')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return PaylaterBillModel.fromJson(data);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Cairkan dana paylater ke wallet
  Future<Map<String, dynamic>> disbursePaylater({
    required String userId,
    required String walletId,
    required double amount,
    required int tenorMonths,
  }) async {
    try {
      final account = await getAccount(userId);
      if (account == null) {
        throw const AppException(message: 'Akun paylater tidak ditemukan');
      }
      if (account.status != PaylaterStatus.active) {
        throw const AppException(message: 'Akun paylater tidak aktif');
      }
      if (amount > account.remainingLimit) {
        throw const AppException(
            message: 'Jumlah melebihi sisa limit paylater');
      }

      // Calculate interest
      final interestAmount = amount * (account.interestRate / 100) * tenorMonths;
      final totalDue = amount + interestAmount;
      final dueDate = DateTime.now().add(Duration(days: tenorMonths * 30));

      // Add balance to wallet
      await _walletRepository.addBalance(userId: userId, amount: amount);

      // Create transaction record
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final refCode =
          'PL${timestamp.substring(timestamp.length - 8)}';

      final txData = await _client.from('transactions').insert({
        'sender_id': userId,
        'receiver_id': userId,
        'wallet_id': walletId,
        'type': 'paylater_disbursement',
        'amount': amount,
        'fee': 0,
        'status': 'success',
        'note': 'Pencairan Paylater',
        'ref_code': refCode,
      }).select().single();

      // Create bill
      final billData = await _client.from('paylater_bills').insert({
        'paylater_id': account.id,
        'user_id': userId,
        'principal_amount': amount,
        'interest_amount': interestAmount,
        'total_due': totalDue,
        'tenor_months': tenorMonths,
        'due_date': DateTimeUtils.toLocalDateOnlyString(dueDate),
        'status': 'active',
        'transaction_id': txData['id'],
      }).select().single();

      // Update used limit
      await _client
          .from('paylater_accounts')
          .update({'used_limit': account.usedLimit + amount})
          .eq('id', account.id);

      return {
        'transaction': TransactionModel.fromJson(txData),
        'bill': PaylaterBillModel.fromJson(billData),
      };
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  /// Bayar tagihan paylater dari wallet
  Future<PaylaterBillModel> payBill({
    required String billId,
    required String userId,
    required String walletId,
  }) async {
    try {
      final bill = await getBillById(billId);
      if (bill == null) {
        throw const AppException(message: 'Tagihan tidak ditemukan');
      }
      if (bill.status == BillStatus.paid) {
        throw const AppException(message: 'Tagihan sudah dibayar');
      }

      // Deduct from wallet
      await _walletRepository.deductBalance(
        userId: userId,
        amount: bill.totalDue,
      );

      // Create payment transaction
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final refCode = 'PP${timestamp.substring(timestamp.length - 8)}';

      await _client.from('transactions').insert({
        'sender_id': userId,
        'receiver_id': userId,
        'wallet_id': walletId,
        'type': 'paylater_payment',
        'amount': bill.totalDue,
        'fee': 0,
        'status': 'success',
        'note': 'Pembayaran Tagihan Paylater',
        'ref_code': refCode,
      });

      // Update bill status
      final updatedBill = await _client
          .from('paylater_bills')
          .update({
            'status': 'paid',
            'paid_at': DateTimeUtils.toUtcIsoString(DateTime.now()),
          })
          .eq('id', billId)
          .select()
          .single();

      // Reduce used limit
      final account = await getAccount(userId);
      if (account != null) {
        final newUsed =
            (account.usedLimit - bill.principalAmount).clamp(0, double.infinity);
        await _client
            .from('paylater_accounts')
            .update({'used_limit': newUsed})
            .eq('id', account.id);
      }

      return PaylaterBillModel.fromJson(updatedBill);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  /// Bayar QRIS dengan PayLater
  Future<Map<String, dynamic>> payWithPaylaterQris({
    required String userId,
    required String walletId,
    required double amount,
    required int tenorMonths,
    required String merchantName,
    required String merchantCity,
    String? note,
  }) async {
    try {
      final account = await getAccount(userId);
      if (account == null) {
        throw const AppException(message: 'Akun PayLater tidak ditemukan');
      }
      if (account.status != PaylaterStatus.active) {
        throw const AppException(message: 'Akun PayLater tidak aktif');
      }
      if (amount > account.remainingLimit) {
        throw const AppException(
            message: 'Jumlah melebihi sisa limit PayLater');
      }

      // Calculate interest
      final interestAmount = amount * (account.interestRate / 100) * tenorMonths;
      final totalDue = amount + interestAmount;
      final dueDate = DateTime.now().add(Duration(days: tenorMonths * 30));

      // Create QRIS transaction with PayLater
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final refCode = 'QPL${timestamp.substring(timestamp.length - 8)}';

      final txData = await _client.from('transactions').insert({
        'sender_id': userId,
        'receiver_id': userId,
        'wallet_id': walletId,
        'type': 'qris_paylater',
        'amount': amount,
        'fee': 0,
        'status': 'success',
        'note': note ?? 'Pembayaran QRIS dengan PayLater ke $merchantName',
        'ref_code': refCode,
        'metadata': {
          'merchant_name': merchantName,
          'merchant_city': merchantCity,
          'payment_method': 'paylater',
        },
      }).select().single();

      // Create bill
      final billData = await _client.from('paylater_bills').insert({
        'paylater_id': account.id,
        'user_id': userId,
        'principal_amount': amount,
        'interest_amount': interestAmount,
        'total_due': totalDue,
        'tenor_months': tenorMonths,
        'due_date': DateTimeUtils.toLocalDateOnlyString(dueDate),
        'status': 'active',
        'transaction_id': txData['id'],
        'payment_type': 'qris',
        'merchant_info': {
          'merchant_name': merchantName,
          'merchant_city': merchantCity,
        },
      }).select().single();

      // Update used limit
      await _client
          .from('paylater_accounts')
          .update({'used_limit': account.usedLimit + amount})
          .eq('id', account.id);

      return {
        'transaction': TransactionModel.fromJson(txData),
        'bill': PaylaterBillModel.fromJson(billData),
      };
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  /// Transfer ke user dengan PayLater
  Future<Map<String, dynamic>> payWithPaylaterTransfer({
    required String userId,
    required String walletId,
    required String receiverId,
    required String receiverWalletId,
    required double amount,
    required int tenorMonths,
    required String receiverUsername,
    required String receiverFullName,
    String? note,
  }) async {
    try {
      final account = await getAccount(userId);
      if (account == null) {
        throw const AppException(message: 'Akun PayLater tidak ditemukan');
      }
      if (account.status != PaylaterStatus.active) {
        throw const AppException(message: 'Akun PayLater tidak aktif');
      }
      if (amount > account.remainingLimit) {
        throw const AppException(
            message: 'Jumlah melebihi sisa limit PayLater');
      }

      // Calculate interest
      final interestAmount = amount * (account.interestRate / 100) * tenorMonths;
      final totalDue = amount + interestAmount;
      final dueDate = DateTime.now().add(Duration(days: tenorMonths * 30));

      // Add balance to receiver's wallet
      await _walletRepository.addBalance(
        userId: receiverId,
        amount: amount,
      );

      // Create transfer transaction with PayLater
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final refCode = 'TPL${timestamp.substring(timestamp.length - 8)}';

      final txData = await _client.from('transactions').insert({
        'sender_id': userId,
        'receiver_id': receiverId,
        'wallet_id': walletId,
        'type': 'transfer_paylater',
        'amount': amount,
        'fee': 0,
        'status': 'success',
        'note': note ?? 'Transfer dengan PayLater ke @$receiverUsername',
        'ref_code': refCode,
        'metadata': {
          'receiver_username': receiverUsername,
          'receiver_full_name': receiverFullName,
          'payment_method': 'paylater',
        },
      }).select().single();

      // Create bill
      final billData = await _client.from('paylater_bills').insert({
        'paylater_id': account.id,
        'user_id': userId,
        'principal_amount': amount,
        'interest_amount': interestAmount,
        'total_due': totalDue,
        'tenor_months': tenorMonths,
        'due_date': DateTimeUtils.toLocalDateOnlyString(dueDate),
        'status': 'active',
        'transaction_id': txData['id'],
        'payment_type': 'transfer',
        'recipient_info': {
          'user_id': receiverId,
          'username': receiverUsername,
          'full_name': receiverFullName,
        },
      }).select().single();

      // Update used limit
      await _client
          .from('paylater_accounts')
          .update({'used_limit': account.usedLimit + amount})
          .eq('id', account.id);

      return {
        'transaction': TransactionModel.fromJson(txData),
        'bill': PaylaterBillModel.fromJson(billData),
      };
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  Future<Map<String, dynamic>> payWithPaylaterBankTransfer({
    required String userId,
    required String walletId,
    required double amount,
    required double fee,
    required int tenorMonths,
    required String bankName,
    required String accountNumber,
    String? note,
  }) async {
    try {
      final account = await getAccount(userId);
      if (account == null) {
        throw const AppException(message: 'Akun PayLater tidak ditemukan');
      }
      if (account.status != PaylaterStatus.active) {
        throw const AppException(message: 'Akun PayLater tidak aktif');
      }

      final totalAmount = amount + fee;
      if (totalAmount > account.remainingLimit) {
        throw const AppException(
            message: 'Jumlah melebihi sisa limit PayLater');
      }

      // Calculate interest
      final interestAmount = amount * (account.interestRate / 100) * tenorMonths;
      final totalDue = amount + interestAmount;
      final dueDate = DateTime.now().add(Duration(days: tenorMonths * 30));

      // Create bank transfer transaction with PayLater
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final refCode = 'BPL${timestamp.substring(timestamp.length - 8)}';

      final txData = await _client.from('transactions').insert({
        'sender_id': userId,
        'wallet_id': walletId,
        'type': 'bank_transfer_paylater',
        'amount': amount,
        'fee': fee,
        'status': 'success',
        'note': note ?? 'Transfer bank ke $bankName dengan PayLater',
        'ref_code': refCode,
        'metadata': {
          'bank_name': bankName,
          'account_number': accountNumber,
          'payment_method': 'paylater',
        },
      }).select().single();

      // Create bill
      final billData = await _client.from('paylater_bills').insert({
        'paylater_id': account.id,
        'user_id': userId,
        'principal_amount': totalAmount,
        'interest_amount': interestAmount,
        'total_due': totalDue + (fee * (account.interestRate / 100) * tenorMonths),
        'tenor_months': tenorMonths,
        'due_date': DateTimeUtils.toLocalDateOnlyString(dueDate),
        'status': 'active',
        'transaction_id': txData['id'],
        'payment_type': 'bank_transfer',
        'merchant_info': {
          'bank_name': bankName,
          'account_number': accountNumber,
        },
      }).select().single();

      // Update used limit
      await _client
          .from('paylater_accounts')
          .update({'used_limit': account.usedLimit + totalAmount})
          .eq('id', account.id);

      return {
        'transaction': TransactionModel.fromJson(txData),
        'bill': PaylaterBillModel.fromJson(billData),
      };
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }
}
