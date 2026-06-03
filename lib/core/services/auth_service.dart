import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService();

  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<bool> isNicknameTaken(String nickname) async {
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('nickname', nickname.trim())
        .maybeSingle();

    return data != null;
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final isTaken = await isNicknameTaken(nickname);

    if (isTaken) {
      throw Exception('Biệt danh đã tồn tại');
    }

    final AuthResponse res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = res.user;

    if (user == null) {
      throw Exception('Không tạo được tài khoản');
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'email': email.trim(),
      'nickname': nickname.trim(),
      'role': 'user',
      'status': 'active',
    });

    await _client.from('user_settings').insert({
      'profile_id': user.id,
      'account_mode': 'public',
      'allow_location_tracking': false,
      'location_mode': 'none',
      'allow_friend_suggestion': true,
      'allow_place_suggestion': true,
      'allow_notification': true,
    });
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = _client.auth.currentUser;

    if (user != null) {
      await _client
          .from('profiles')
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);
    }
  }

  Future<String> uploadAvatar(File file) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage
        .from('avatars')
        .upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

    await _client
        .from('profiles')
        .update({
          'avatar_url': publicUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);

    return publicUrl;
  }

  Future<void> saveInterests(List<String> optionCodes) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    await _client.from('profile_interests').delete().eq('profile_id', user.id);

    if (optionCodes.isEmpty) return;

    final rows = optionCodes.map((code) {
      return {'profile_id': user.id, 'option_code': code};
    }).toList();

    await _client.from('profile_interests').insert(rows);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final data = await _client
        .from('profiles')
        .select('id, nickname, email, avatar_url')
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }
}
