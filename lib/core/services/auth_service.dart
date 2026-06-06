import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes/app_routes.dart';

class AuthService {
  AuthService();

  static const String demoOtp = '123456';
  static const String lockedAccountMessage = 'Tài khoản của bạn đã bị khóa';

  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  // =========================
  // PROFILE / USER SETTINGS
  // =========================

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    await ensureProfileAfterOAuth();

    final data = await _client
        .from('profiles')
        .select(
          'id, email, phone, nickname, full_name, avatar_url, bio, facebook_url, role, status, lock_reason',
        )
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  Future<void> checkCurrentAccountNotLocked() async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    final profile = await _client
        .from('profiles')
        .select('id, status, lock_reason')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      return;
    }

    final status = profile['status']?.toString().trim().toLowerCase();

    if (status == 'locked') {
      await _client.auth.signOut();
      throw Exception(lockedAccountMessage);
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (_) {
      // Nếu DB chưa có cột last_login_at thì bỏ qua để app không bị lỗi.
    }
  }

  Future<void> _ensureUserSettings(String profileId) async {
    try {
      final existed = await _client
          .from('user_settings')
          .select('profile_id')
          .eq('profile_id', profileId)
          .maybeSingle();

      if (existed != null) {
        return;
      }

      await _client.from('user_settings').insert({
        'profile_id': profileId,
        'account_mode': 'public',
        'allow_location_tracking': false,
        'location_mode': 'none',
        'allow_friend_suggestion': true,
        'allow_place_suggestion': true,
        'allow_notification': true,
      });
    } catch (_) {
      // Nếu bị trùng do chạy song song hoặc RLS khác thì không cho app crash.
    }
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
      try {
        final data = await _client
            .from('profiles')
            .select('id')
            .eq('nickname', cleanNickname)
            .maybeSingle();

        return data != null;
      } catch (_) {
        return false;
      }
    }
  }

  Future<String> _makeUniqueNickname(String baseNickname) async {
    String cleaned = baseNickname
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

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

  /// true  = vừa tạo profile mới
  /// false = profile đã tồn tại hoặc chưa có user
  Future<bool> ensureProfileAfterOAuth() async {
    final user = currentUser;

    if (user == null) {
      return false;
    }

    final existedProfile = await _client
        .from('profiles')
        .select('id, status')
        .eq('id', user.id)
        .maybeSingle();

    if (existedProfile != null) {
      await checkCurrentAccountNotLocked();
      await _ensureUserSettings(user.id);
      await _updateLastLogin(user.id);
      return false;
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

    final now = DateTime.now().toIso8601String();

    try {
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
        'updated_at': now,
        'last_login_at': now,
      });
    } catch (_) {
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
        'updated_at': now,
      });
    }

    await _ensureUserSettings(user.id);

    return true;
  }

  Future<String> getNextRouteAfterAuth({
    bool forceAvatarForNewOAuthUser = false,
  }) async {
    final user = currentUser;

    if (user == null) {
      return AppRoutes.start;
    }

    await ensureProfileAfterOAuth();
    await checkCurrentAccountNotLocked();

    return AppRoutes.home;
  }

  // =========================
  // EMAIL AUTH
  // =========================

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final cleanNickname = nickname.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Email không được để trống');
    }

    if (!cleanEmail.contains('@')) {
      throw Exception('Email không hợp lệ');
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

    try {
      final AuthResponse response = await _client.auth.signUp(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Không tạo được tài khoản');
      }

      final now = DateTime.now().toIso8601String();

      try {
        await _client.from('profiles').insert({
          'id': user.id,
          'email': cleanEmail,
          'phone': null,
          'nickname': cleanNickname,
          'full_name': null,
          'avatar_url': null,
          'bio': '',
          'facebook_url': '',
          'role': 'user',
          'status': 'active',
          'updated_at': now,
          'last_login_at': now,
        });
      } catch (_) {
        await _client.from('profiles').insert({
          'id': user.id,
          'email': cleanEmail,
          'phone': null,
          'nickname': cleanNickname,
          'full_name': null,
          'avatar_url': null,
          'bio': '',
          'facebook_url': '',
          'role': 'user',
          'status': 'active',
          'updated_at': now,
        });
      }

      await _ensureUserSettings(user.id);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('Email không được để trống');
    }

    if (cleanPassword.isEmpty) {
      throw Exception('Mật khẩu không được để trống');
    }

    try {
      await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = currentUser;

      if (user != null) {
        await checkCurrentAccountNotLocked();
        await _ensureUserSettings(user.id);
        await _updateLastLogin(user.id);
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // =========================
  // GOOGLE AUTH
  // =========================

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'gomate://login-callback',
      authScreenLaunchMode: LaunchMode.platformDefault,
    );
  }

  // =========================
  // PHONE DEMO AUTH
  // =========================

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

    try {
      final AuthResponse response = await _client.auth.signUp(
        email: virtualEmail,
        password: cleanPassword,
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Không tạo được tài khoản bằng SĐT');
      }

      final now = DateTime.now().toIso8601String();

      try {
        await _client.from('profiles').insert({
          'id': user.id,
          'email': virtualEmail,
          'phone': normalizedPhone,
          'nickname': cleanNickname,
          'full_name': null,
          'avatar_url': null,
          'bio': '',
          'facebook_url': '',
          'role': 'user',
          'status': 'active',
          'updated_at': now,
          'last_login_at': now,
        });
      } catch (_) {
        await _client.from('profiles').insert({
          'id': user.id,
          'email': virtualEmail,
          'phone': normalizedPhone,
          'nickname': cleanNickname,
          'full_name': null,
          'avatar_url': null,
          'bio': '',
          'facebook_url': '',
          'role': 'user',
          'status': 'active',
          'updated_at': now,
        });
      }

      await _ensureUserSettings(user.id);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signInWithPhoneDemo({
    required String phone,
    required String password,
  }) async {
    if (!isValidVietnamPhone(phone)) {
      throw Exception('Số điện thoại không hợp lệ');
    }

    final virtualEmail = phoneToVirtualEmail(phone);

    await signInWithEmail(email: virtualEmail, password: password);
  }

  // =========================
  // FORGOT PASSWORD DEMO OTP
  // =========================

  String requestEmailOtpDemo(String email) {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
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
    final cleanNewPassword = newPassword.trim();

    if (cleanNewPassword.length < 8) {
      throw Exception('Mật khẩu tối thiểu 8 ký tự');
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final session = _client.auth.currentSession;
    final user = session?.user;

    if (session == null || user == null || user.email == null) {
      throw Exception('Chưa đăng nhập hoặc phiên đăng nhập đã hết hạn');
    }

    final cleanOldPassword = oldPassword.trim();
    final cleanNewPassword = newPassword.trim();
    final cleanConfirmPassword = confirmPassword.trim();

    if (cleanOldPassword.isEmpty) {
      throw Exception('Vui lòng nhập mật khẩu cũ');
    }

    if (cleanNewPassword.length < 8) {
      throw Exception('Mật khẩu mới tối thiểu 8 ký tự');
    }

    if (cleanNewPassword != cleanConfirmPassword) {
      throw Exception('Xác nhận mật khẩu mới không khớp');
    }

    try {
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: cleanOldPassword,
      );

      await checkCurrentAccountNotLocked();

      await _client.auth.updateUser(UserAttributes(password: cleanNewPassword));
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // =========================
  // SURVEY / INTERESTS
  // =========================

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

  // =========================
  // AVATAR
  // =========================

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

  // =========================
  // SIGN OUT
  // =========================

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
