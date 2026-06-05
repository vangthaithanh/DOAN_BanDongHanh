import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileConnectionUser {
  final String id;
  final String nickname;
  final String fullName;
  final String avatarUrl;

  const ProfileConnectionUser({
    required this.id,
    required this.nickname,
    required this.fullName,
    required this.avatarUrl,
  });

  factory ProfileConnectionUser.fromMap(Map<String, dynamic> map) {
    return ProfileConnectionUser(
      id: (map['id'] ?? '').toString(),
      nickname: (map['nickname'] ?? '').toString().trim(),
      fullName: (map['full_name'] ?? '').toString().trim(),
      avatarUrl: (map['avatar_url'] ?? '').toString().trim(),
    );
  }
}

class ProfileConnectionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProfileConnectionUser>> loadConnections({
    required String targetUserId,
    required String type,
  }) async {
    if (targetUserId.isEmpty) {
      return [];
    }

    final data = await _client.rpc(
      'get_profile_connections',
      params: {'p_target_user_id': targetUserId, 'p_type': type},
    );

    return (data as List)
        .map(
          (item) =>
              ProfileConnectionUser.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((user) => user.id.isNotEmpty)
        .toList();
  }
}
