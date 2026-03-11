import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import '../../core/errors/app_exception.dart';

class WalletRepository {
  final SupabaseClient _client;

  WalletRepository({required SupabaseClient client}) : _client = client;

  Future<WalletModel?> getWallet(String userId) async {
    try {
      final data = await _client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return WalletModel.fromJson(data);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<String?> getRecipientWalletIdForTransfer(String userId) async {
    try {
      final data = await _client.rpc(
        'get_recipient_wallet_id',
        params: {'target_user_id': userId},
      );

      if (data == null) return null;
      return data.toString();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Execute atomic transfer between wallets using RPC (bypasses RLS)
  Future<Map<String, String>> executeAtomicTransfer({
    required String senderId,
    required String receiverId,
    required double amount,
    double fee = 0,
  }) async {
    try {
      final result = await _client.rpc(
        'execute_wallet_transfer',
        params: {
          'sender_user_id': senderId,
          'receiver_user_id': receiverId,
          'transfer_amount': amount,
          'transfer_fee': fee,
        },
      );

      if (result == null) {
        throw const AppException(message: 'Transfer gagal');
      }

      return {
        'sender_wallet_id': result['sender_wallet_id'].toString(),
        'receiver_wallet_id': result['receiver_wallet_id'].toString(),
      };
    } on PostgrestException catch (e) {
      // Handle specific Postgres exceptions from RPC
      if (e.message.contains('Insufficient balance')) {
        throw const InsufficientBalanceException();
      } else if (e.message.contains('wallet not found')) {
        throw const AppException(message: 'Wallet tidak ditemukan');
      }
      throw AppException(message: e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  Future<WalletModel> topUp({
    required String userId,
    required double amount,
  }) async {
    try {
      final wallet = await getWallet(userId);
      if (wallet == null) throw const AppException(message: 'Wallet tidak ditemukan');

      final newBalance = wallet.balance + amount;
      final data = await _client
          .from('wallets')
          .update({'balance': newBalance})
          .eq('user_id', userId)
          .select()
          .single();
      return WalletModel.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  Future<WalletModel> deductBalance({
    required String userId,
    required double amount,
  }) async {
    try {
      final wallet = await getWallet(userId);
      if (wallet == null) throw const AppException(message: 'Wallet tidak ditemukan');
      if (wallet.balance < amount) throw const InsufficientBalanceException();

      final newBalance = wallet.balance - amount;
      final data = await _client
          .from('wallets')
          .update({'balance': newBalance})
          .eq('user_id', userId)
          .select()
          .single();
      return WalletModel.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  Future<WalletModel> addBalance({
    required String userId,
    required double amount,
  }) async {
    try {
      final wallet = await getWallet(userId);
      if (wallet == null) throw const AppException(message: 'Wallet tidak ditemukan');

      final newBalance = wallet.balance + amount;
      final data = await _client
          .from('wallets')
          .update({'balance': newBalance})
          .eq('user_id', userId)
          .select()
          .single();
      return WalletModel.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }
}
