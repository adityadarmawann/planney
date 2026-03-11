import 'package:flutter/foundation.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';
import '../core/errors/app_exception.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  TransactionModel? _lastTransaction;
  String? _currentUserId;

  TransactionProvider({
    required TransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TransactionModel? get lastTransaction => _lastTransaction;

  bool _isTransactionVisibleForUser(TransactionModel tx, String userId) {
    if (tx.typeString == 'transfer_in') {
      return tx.receiverId == userId;
    }

    if (tx.typeString == 'transfer_out') {
      return tx.senderId == userId;
    }

    return tx.senderId == userId || tx.receiverId == userId;
  }

  List<TransactionModel> getFilteredTransactions(String? type) {
    if (type == null) return _transactions;
    if (type == 'paylater') {
      return _transactions
          .where((t) => t.typeString == 'paylater_disbursement' || 
                       t.typeString == 'paylater_payment')
          .toList();
    }
    // Filter transfer masuk: hanya tampilkan jika user adalah penerima
    if (type == 'transfer_in') {
      return _transactions
          .where((t) => t.typeString == 'transfer_in' && 
                       t.receiverId == _currentUserId)
          .toList();
    }
    // Filter transfer keluar: hanya tampilkan jika user adalah pengirim
    if (type == 'transfer_out') {
      return _transactions
          .where((t) => t.typeString == 'transfer_out' && 
                       t.senderId == _currentUserId)
          .toList();
    }
    return _transactions
        .where((t) => t.typeString == type)
        .toList();
  }

  Future<void> loadTransactions({required String userId, String? type}) async {
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _transactionRepository.getTransactions(
        userId: userId,
        type: type,
      );

      // Keep timeline consistent with user perspective.
      _transactions = fetched
          .where((tx) => _isTransactionVisibleForUser(tx, userId))
          .toList();
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> topUp({
    required String userId,
    required String walletId,
    required double amount,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastTransaction = await _transactionRepository.createTopUp(
        userId: userId,
        walletId: walletId,
        amount: amount,
        note: note,
      );
      _transactions.insert(0, _lastTransaction!);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> transfer({
    required String senderId,
    required String senderWalletId,
    required String receiverId,
    required String receiverWalletId,
    required double amount,
    double fee = 0,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _transactionRepository.createTransfer(
        senderId: senderId,
        senderWalletId: senderWalletId,
        receiverId: receiverId,
        receiverWalletId: receiverWalletId,
        amount: amount,
        fee: fee,
        note: note,
      );
      _lastTransaction = result['out'];
      _transactions.insert(0, _lastTransaction!);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> bankTransfer({
    required String userId,
    required String walletId,
    required double amount,
    required double fee,
    required String bankName,
    required String accountNumber,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastTransaction = await _transactionRepository.createBankTransfer(
        userId: userId,
        walletId: walletId,
        amount: amount,
        fee: fee,
        bankName: bankName,
        accountNumber: accountNumber,
        note: note,
      );
      _transactions.insert(0, _lastTransaction!);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> qrisPayment({
    required String userId,
    required String walletId,
    required double amount,
    required String merchantName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastTransaction = await _transactionRepository.createQrisPayment(
        userId: userId,
        walletId: walletId,
        amount: amount,
        merchantName: merchantName,
      );
      _transactions.insert(0, _lastTransaction!);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
