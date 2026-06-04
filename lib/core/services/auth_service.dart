import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes/app_routes.dart';

/// NOTE SỬA:
/// File này xử lý Supabase Auth + profiles + avatar.
///
/// SỬA CHÍNH:
/// 1. uploadAvatar() upload đúng path <user_id>/avatar_xxx.jpg để khớp Storage RLS.
/// 2. signUpWithEmail() insert profiles với id = auth.uid().
/// 3. Không update role/status/email khi user thường sửa profile.
/// 4. Thêm getNextRouteAfterAuth() để xử lý Google login:
///    - chưa có avatar -> thêm avatar
///    - chưa khảo sát -> màn câu hỏi
///    - đủ rồi -> home
class AuthService {
  AuthService();

  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final data = await _client
        .from('profiles')
        .select(
          'id, email, nickname, full_name, avatar_url, bio, facebook_url, role, status',
        )
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  /// NOTE SỬA:
  /// Dùng RPC is_nickname_taken nếu Supabase có hàm này.
  /// Không select profiles trực tiếp để tránh lỗi RLS recursion.
  Future<bool> isNicknameTaken(String nickname) async {
    final cleanNickname = nickname.trim();

    if (cleanNickname.isEmpty) {
      return false;
    }

    try {
      final result = await _client.rpc(
        'is_nickname_taken',
        params: {'p_nickname': cleanNickname},
      );

      return result == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final cleanEmail = email.trim();
    final cleanNickname = nickname.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Email không được để trống');
    }

    if (password.length < 8) {
      throw Exception('Mật khẩu tối thiểu 8 ký tự');
    }

    if (cleanNickname.length < 3) {
      throw Exception('Biệt danh tối thiểu 3 ký tự');
    }

    final isTaken = await isNicknameTaken(cleanNickname);

    if (isTaken) {
      throw Exception('Biệt danh đã tồn tại');
    }

    final AuthResponse response = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Không tạo được tài khoản');
    }

    /// NOTE SỬA:
    /// RLS profiles_insert_own yêu cầu id = auth.uid().
    /// Vì vậy id trong profiles bắt buộc là user.id.
    await _client.from('profiles').insert({
      'id': user.id,
      'email': cleanEmail,
      'nickname': cleanNickname,
      'full_name': null,
      'bio': '',
      'facebook_url': '',
      'role': 'user',
      'status': 'active',
      'updated_at': DateTime.now().toIso8601String(),
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

    final user = currentUser;

    if (user != null) {
      try {
        await _client
            .from('profiles')
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', user.id);
      } catch (_) {
        /// NOTE:
        /// Nếu bảng chưa có last_login_at thì bỏ qua.
      }
    }
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'gomate://login-callback',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  /// NOTE SỬA:
  /// Hàm này dùng sau khi Google login.
  /// Nếu tài khoản Google mới chưa có profile thì tự tạo profile.
  Future<void> ensureProfileAfterOAuth() async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    final existedProfile = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existedProfile != null) {
      return;
    }

    final email = user.email ?? '';
    final metadata = user.userMetadata ?? {};

    final fullName =
        metadata['full_name']?.toString() ?? metadata['name']?.toString() ?? '';

    final avatarUrl =
        metadata['avatar_url']?.toString() ?? metadata['picture']?.toString();

    String nickname = '';

    if (fullName.trim().isNotEmpty) {
      nickname = fullName.trim().replaceAll(' ', '_').toLowerCase();
    } else if (email.contains('@')) {
      nickname = email.split('@').first;
    } else {
      nickname = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }

    nickname = await _makeUniqueNickname(nickname);

    await _client.from('profiles').insert({
      'id': user.id,
      'email': email,
      'nickname': nickname,
      'full_name': fullName.trim().isEmpty ? null : fullName.trim(),
      'avatar_url': avatarUrl,
      'bio': '',
      'facebook_url': '',
      'role': 'user',
      'status': 'active',
      'updated_at': DateTime.now().toIso8601String(),
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

  Future<String> _makeUniqueNickname(String baseNickname) async {
    String cleaned = baseNickname
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (cleaned.length < 3) {
      cleaned = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }

    String nickname = cleaned;
    int count = 1;

    while (await isNicknameTaken(nickname)) {
      nickname = '${cleaned}_$count';
      count++;
    }

    return nickname;
  }

  /// NOTE SỬA:
  /// Hàm kiểm tra user đã trả lời khảo sát chưa.
  /// Nếu profile_interests chưa có dòng nào thì xem như chưa khảo sát.
  Future<bool> hasAnsweredSurvey() async {
    final user = currentUser;

    if (user == null) {
      return false;
    }

    try {
      final rows = await _client
          .from('profile_interests')
          .select('profile_id')
          .eq('profile_id', user.id)
          .limit(1);

      return (rows as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// NOTE SỬA QUAN TRỌNG:
  /// Hàm này quyết định sau đăng nhập sẽ đi đâu.
  ///
  /// Luồng:
  /// - Chưa login -> start
  /// - Google login mới chưa có profile -> tự tạo profile
  /// - Chưa có avatar -> addAvatar
  /// - Chưa trả lời câu hỏi -> surveyIntro
  /// - Đủ rồi -> home
  Future<String> getNextRouteAfterAuth() async {
    final user = currentUser;

    if (user == null) {
      return AppRoutes.start;
    }

    await ensureProfileAfterOAuth();

    final profile = await getCurrentProfile();

    if (profile == null) {
      return AppRoutes.start;
    }

    final avatarUrl = profile['avatar_url']?.toString() ?? '';

    if (avatarUrl.trim().isEmpty) {
      return AppRoutes.addAvatar;
    }

    final hasSurvey = await hasAnsweredSurvey();

    if (!hasSurvey) {
      return AppRoutes.surveyIntro;
    }

    return AppRoutes.home;
  }

  Future<String> uploadAvatar(File file) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final ext = file.path.split('.').last.toLowerCase();

    /// NOTE SỬA QUAN TRỌNG:
    /// Storage RLS bắt user upload vào thư mục chính mình:
    /// <user_id>/<filename>
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

    /// NOTE SỬA:
    /// Chỉ update avatar_url + updated_at.
    /// Không update role/status/email vì trigger RLS sẽ chặn.
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
    final user = currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    await _client.from('profile_interests').delete().eq('profile_id', user.id);

    if (optionCodes.isEmpty) {
      return;
    }

    final rows = optionCodes.map((code) {
      return {'profile_id': user.id, 'option_code': code};
    }).toList();

    await _client.from('profile_interests').insert(rows);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
