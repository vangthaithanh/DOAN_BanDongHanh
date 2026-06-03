import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService();

  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  // ================================
  // LẤY PROFILE HIỆN TẠI
  // Dùng cho màn khảo sát / profile
  // ================================
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

  // ================================
  // KIỂM TRA BIỆT DANH TRÙNG
  // Dùng khi đăng ký email/password
  // ================================
  Future<bool> isNicknameTaken(String nickname) async {
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('nickname', nickname.trim())
        .maybeSingle();

    return data != null;
  }

  // ================================
  // ĐĂNG KÝ BẰNG EMAIL + PASSWORD
  // Sau khi Supabase Auth tạo user,
  // mình tự tạo thêm profiles + user_settings
  // ================================
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

  // ================================
  // ĐĂNG NHẬP EMAIL + PASSWORD
  // ================================
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
      await _client
          .from('profiles')
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);
    }
  }

  // ================================
  // THÊM MỚI: ĐĂNG NHẬP GOOGLE
  // Hàm này mở trình duyệt để user chọn Gmail.
  // Sau khi xong, Supabase sẽ redirect về:
  // gomate://login-callback
  // ================================
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'gomate://login-callback',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  // ================================
  // THÊM MỚI: TẠO PROFILE SAU GOOGLE LOGIN
  // Vì Google OAuth chỉ tạo user trong Authentication.
  // Nếu chưa có dòng trong profiles thì tự tạo.
  // ================================
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
      'full_name': fullName.isEmpty ? null : fullName,
      'avatar_url': avatarUrl,
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

  // ================================
  // THÊM MỚI: TẠO NICKNAME KHÔNG TRÙNG
  // Ví dụ Google trả tên "Bui Trong"
  // thì nickname là bui_trong.
  // Nếu trùng thì thành bui_trong_1, bui_trong_2...
  // ================================
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

  // ================================
  // UPLOAD AVATAR
  // Dùng cho đăng ký thường khi chọn ảnh đại diện
  // ================================
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

  // ================================
  // LƯU KHẢO SÁT SỞ THÍCH
  // Xóa sở thích cũ rồi thêm danh sách mới
  // ================================
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

  // ================================
  // ĐĂNG XUẤT
  // ================================
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
