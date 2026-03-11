import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../../core/errors/app_exception.dart';
import 'wallet_repository.dart';

class TransactionRepository {
  final SupabaseClient _client;
  final WalletRepository _walletRepository;

  TransactionRepository({
    required SupabaseClient client,
    required WalletRepository walletRepository,
  })  : _client = client,
        _walletRepository = walletRepository;

  String _generateRefCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'SP${timestamp.substring(timestamp.length - 8)}';
  }

  Future<List<TransactionModel>> getTransactions({
    required String userId,
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final data = await query;
      return (data as List)
          .map((e) => TransactionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final data = await _client
          .from('transactions')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return TransactionModel.fromJson(data);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<TransactionModel> createTopUp({
    required String userId,
    required String walletId,
    required double amount,
    String? note,
  }) async {
    try {
      await _walletRepository.addBalance(userId: userId, amount: amount);

      final txData = await _client.from('transactions').insert({
        'sender_id': userId,
        'receiver_id': userId,
        'wallet_id': walletId,
        'type': 'topup',
        'amount': amount,
        'fee': 0,
        'status': 'success',
        'note': note ?? 'Top Up Saldo',
        'ref_code': _generateRefCode(),
      }).select().single();

      return TransactionModel.fromJson(txData);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  Future<Map<String, TransactionModel>> createTransfer({
    required String senderId,
    required String senderWalletId,
    required String receiverId,
    required String receiverWalletId,
    required double amount,
    double fee = 0,
    String? note,
  }) async {
    try {
      if (senderId == receiverId) {
        throw const AppException(
          message: 'Tidak bisa transfer ke akun sendiri',
        );
      }

      if (senderWalletId == receiverWalletId) {
        throw const AppException(
          message: 'Wallet tujuan tidak valid',
        );
      }

      // Execute atomic wallet transfer via RPC (bypasses RLS)
      final walletIds = await _walletRepository.executeAtomicTransfer(
        senderId: senderId,
        receiverId: receiverId,
        amount: amount,
        fee: fee,
      );

      // Use wallet IDs returned from RPC
      final actualSenderWalletId = walletIds['sender_wallet_id']!;
      final actualReceiverWalletId = walletIds['receiver_wallet_id']!;

      final refCode = _generateRefCode();

      final outTx = await _client.from('transactions').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'wallet_id': actualSenderWalletId,
        'type': 'transfer_out',
        'amount': amount,
        'fee': fee,
        'status': 'success',
        'note': note,
        'ref_code': refCode,
        'metadata': {'receiver_id': receiverId},
      }).select().single();

      final inTx = await _client.from('transactions').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'wallet_id': actualReceiverWalletId,
        'type': 'transfer_in',
        'amount': amount,
        'fee': 0,
        'status': 'success',
        'note': note,
        'ref_code': '${refCode}IN',
        'metadata': {'sender_id': senderId},
      }).select().single();

      return {
        'out': TransactionModel.fromJson(outTx),
        'in': TransactionModel.fromJson(inTx),
      };
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  Future<TransactionModel> createBankTransfer({
    required String userId,
    required String walletId,
    required double amount,
    required double fee,
    required String bankName,
    required String accountNumber,
    String? note,
  }) async {
    try {
      final totalDeduct = amount + fee;
      await _walletRepository.deductBalance(
        userId: userId,
        amount: totalDeduct,
      );

      final txData = await _client.from('transactions').insert({
        'sender_id': userId,
        'wallet_id': walletId,
        'type': 'bank_transfer',
        'amount': amount,
        'fee': fee,
        'status': 'success',
        'note': note ?? 'Transfer ke $bankName',
        'ref_code': _generateRefCode(),
        'metadata': {
          'bank_name': bankName,
          'account_number': accountNumber,
        },
      }).select().single();

      return TransactionModel.fromJson(txData);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  Future<TransactionModel> createQrisPayment({
    required String userId,
    required String walletId,
    required double amount,
    required String merchantName,
  }) async {
    try {
      await _walletRepository.deductBalance(userId: userId, amount: amount);

      final txData = await _client.from('transactions').insert({
        'sender_id': userId,
        'wallet_id': walletId,
        'type': 'bank_transfer',
        'amount': amount,
        'fee': 0,
        'status': 'success',
        'note': 'Pembayaran QRIS - $merchantName',
        'ref_code': _generateRefCode(),
        'metadata': {'merchant_name': merchantName, 'payment_method': 'qris'},
      }).select().single();

      return TransactionModel.fromJson(txData);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }
}
