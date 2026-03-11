import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../../core/errors/app_exception.dart';

class AuthRepository {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required SupabaseClient client,
    required GoogleSignIn googleSignIn,
  })  : _client = client,
        _googleSignIn = googleSignIn;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) return null;
      return _fetchUserProfile(response.user!.id);
    } on AuthException catch (e) {
      throw AuthException(
        message: _mapAuthError(e.message),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    try {
      // Normalize username to lowercase for case-insensitive matching
      final normalizedUsername = username.toLowerCase().trim();
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'username': normalizedUsername},
      );
      
      // Check if email confirmation is required
      if (response.user != null && _client.auth.currentSession == null) {
        throw AuthException(
          message: 'Cek email kamu dan lakukan verifikasi untuk melanjutkan',
          code: 'email_confirmation_required',
        );
      }
      
      if (response.user == null) return null;

      // Update user profile with full name and username
      await Future.delayed(const Duration(seconds: 1));
      await _client.from('users').update({
        'full_name': fullName,
        'username': normalizedUsername,
      }).eq('id', response.user!.id);

      // Create wallet for new user (starting balance 0)
      try {
        await _client.from('wallets').insert({
          'user_id': response.user!.id,
          'balance': 0,
        });
      } catch (e) {
        // Wallet might already exist, continue anyway
        debugPrint('Wallet creation failed: $e');
      }

      return _fetchUserProfile(response.user!.id);
    } on AuthException catch (e) {
      throw AuthException(
        message: _mapAuthError(e.message),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Use Supabase's built-in OAuth flow - this is the recommended approach
      // and handles the redirect properly without opening external apps
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.studentplan://login-callback',
      );
      
      // The OAuth flow will redirect, so we return null here
      // The auth state listener will handle the session once redirected back
      return null;
    } on AuthException catch (e) {
      throw AuthException(
        message: _mapAuthError(e.message),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromError(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _client.auth.signOut();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<UserModel?> _fetchUserProfile(String userId) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Email atau kata sandi salah';
    } else if (lower.contains('email already registered') ||
        lower.contains('user already registered')) {
      return 'Email sudah terdaftar';
    } else if (lower.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox kamu';
    } else if (lower.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti';
    }
    return message;
  }
}
