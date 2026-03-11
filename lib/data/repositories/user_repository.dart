import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../core/errors/app_exception.dart';

class UserRepository {
  final SupabaseClient _client;

  UserRepository({required SupabaseClient client}) : _client = client;

  Future<UserModel?> getUserById(String userId) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final cleanUsername = username.toLowerCase().trim();
      final currentUserId = _client.auth.currentUser?.id;
      
      // Exact match - all usernames are now stored in lowercase
      var query = _client
          .from('users')
          .select()
          .eq('username', cleanUsername);

      // Prevent selecting current user as transfer recipient.
      if (currentUserId != null) {
        query = query.neq('id', currentUserId);
      }

      final data = await query.maybeSingle();
      
      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (username != null) updates['username'] = username.toLowerCase().trim();
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final data = await _client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<String?> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final path = 'avatars/$userId/$fileName';
      await _client.storage.from('avatars').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: true),
          );
      final url = _client.storage.from('avatars').getPublicUrl(path);
      return url;
    } catch (e) {
      // Provide more specific error message
      String errorMsg = 'Gagal upload foto profil';
      if (e.toString().contains('Bucket not found') ||
          e.toString().contains('Bucket does not exist')) {
        errorMsg = 'Storage bucket belum dibuat. Hubungi admin.';
      } else if (e.toString().contains('Permission denied')) {
        errorMsg = 'Tidak ada izin untuk upload foto.';
      }
      throw AppException(message: errorMsg, originalError: e);
    }
  }

  Future<bool> deleteAvatar({required String userId}) async {
    try {
      // First, delete all files in user's avatar folder from storage
      try {
        final files = await _client.storage
            .from('avatars')
            .list(path: userId);
        
        if (files.isNotEmpty) {
          final filePaths = files
              .where((f) => f.name.isNotEmpty)
              .map((f) => '$userId/${f.name}')
              .toList();
          
          if (filePaths.isNotEmpty) {
            await _client.storage.from('avatars').remove(filePaths);
          }
        }
      } catch (storageError) {
        // Log storage error but continue with database cleanup
        // This ensures avatar_url is set to null even if file deletion fails
        // Note: File deletion might fail but database update should succeed
      }

      // Then, set avatar_url to null in database
      await _client
          .from('users')
          .update({'avatar_url': null})
          .eq('id', userId);

      return true;
    } catch (e) {
      throw AppException.fromError(e);
    }
  }
}
