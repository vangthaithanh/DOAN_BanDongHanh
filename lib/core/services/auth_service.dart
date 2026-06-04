import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes/app_routes.dart';

/// NOTE SỬA:
/// AuthService dùng cho:
/// - Đăng ký email thật
/// - Đăng nhập email thật
/// - Đăng nhập Google thật
/// - Đăng ký SĐT demo bằng email ảo
/// - Đăng nhập SĐT demo bằng email ảo
/// - OTP demo 123456 cho quên mật khẩu email/SĐT
/// - Upload avatar đúng Storage RLS
class AuthService {
  AuthService();

  static const String demoOtp = '123456';

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
          'id, email, phone, nickname, full_name, avatar_url, bio, facebook_url, role, status',
        )
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

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

    await _client.from('profiles').insert({
      'id': user.id,
      'email': cleanEmail,
      'phone': null,
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
        // Nếu chưa có cột last_login_at thì bỏ qua.
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
      'phone': null,
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

  String normalizePhone(String phone) {
    var text = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');

    if (text.startsWith('+84')) {
      text = '84${text.substring(3)}';
    } else if (text.startsWith('0')) {
      text = '84${text.substring(1)}';
    } else if (!text.startsWith('84')) {
      text = '84$text';
    }

    return text;
  }

  bool isValidVietnamPhone(String phone) {
    final normalized = normalizePhone(phone);
    return RegExp(r'^84[0-9]{9,10}$').hasMatch(normalized);
  }

  String phoneToVirtualEmail(String phone) {
    final normalized = normalizePhone(phone);
    return 'phone_$normalized@gomate.local';
  }

  Future<void> signUpWithPhoneDemo({
    required String phone,
    required String password,
    required String nickname,
  }) async {
    final cleanPhone = phone.trim();
    final normalizedPhone = normalizePhone(cleanPhone);
    final cleanPassword = password.trim();
    final cleanNickname = nickname.trim();

    if (!isValidVietnamPhone(cleanPhone)) {
      throw Exception('Số điện thoại không hợp lệ');
    }

    if (cleanPassword.length < 8) {
      throw Exception('Mật khẩu tối thiểu 8 ký tự');
    }

    if (cleanNickname.length < 3) {
      throw Exception('Biệt danh tối thiểu 3 ký tự');
    }

    final isTaken = await isNicknameTaken(cleanNickname);

    if (isTaken) {
      throw Exception('Biệt danh đã tồn tại');
    }

    final virtualEmail = phoneToVirtualEmail(cleanPhone);

    final AuthResponse response = await _client.auth.signUp(
      email: virtualEmail,
      password: cleanPassword,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Không tạo được tài khoản bằng SĐT');
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'email': virtualEmail,
      'phone': normalizedPhone,
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

  Future<void> signInWithPhoneDemo({
    required String phone,
    required String password,
  }) async {
    final virtualEmail = phoneToVirtualEmail(phone);

    await signInWithEmail(email: virtualEmail, password: password);
  }

  String requestEmailOtpDemo(String email) {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Gmail không hợp lệ');
    }

    return demoOtp;
  }

  String requestPhoneForgotOtpDemo({
    required String phone,
    required String gmail,
  }) {
    if (!isValidVietnamPhone(phone)) {
      throw Exception('Số điện thoại không hợp lệ');
    }

    if (gmail.trim().isEmpty || !gmail.contains('@')) {
      throw Exception('Gmail không hợp lệ');
    }

    return demoOtp;
  }

  bool verifyOtpDemo(String otp) {
    return otp.trim() == demoOtp;
  }

  Future<void> resetPasswordDemo({required String newPassword}) async {
    if (newPassword.trim().length < 8) {
      throw Exception('Mật khẩu tối thiểu 8 ký tự');
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

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
