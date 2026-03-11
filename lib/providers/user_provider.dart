import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import '../core/errors/app_exception.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserProvider({required UserRepository userRepository})
      : _userRepository = userRepository;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _userRepository.getUserById(userId);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? phone,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _userRepository.updateProfile(
        userId: userId,
        fullName: fullName,
        username: username,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      return await _userRepository.uploadAvatar(
        userId: userId,
        bytes: bytes,
        fileName: fileName,
      );
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteAvatar({required String userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userRepository.deleteAvatar(userId: userId);
      // Update user model to clear avatar_url immediately
      if (_user != null) {
        _user = _user!.copyWith(avatarUrl: null);
        notifyListeners(); // Notify immediately to update UI
      }
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
