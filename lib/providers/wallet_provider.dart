import 'package:flutter/foundation.dart';
import '../data/models/wallet_model.dart';
import '../data/repositories/wallet_repository.dart';
import '../core/errors/app_exception.dart';

class WalletProvider extends ChangeNotifier {
  final WalletRepository _walletRepository;

  WalletModel? _wallet;
  bool _isLoading = false;
  String? _errorMessage;

  WalletProvider({required WalletRepository walletRepository})
      : _walletRepository = walletRepository;

  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get balance => _wallet?.balance ?? 0;

  Future<void> loadWallet(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallet = await _walletRepository.getWallet(userId);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> topUp({
    required String userId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallet = await _walletRepository.topUp(userId: userId, amount: amount);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateWallet(WalletModel wallet) {
    _wallet = wallet;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
