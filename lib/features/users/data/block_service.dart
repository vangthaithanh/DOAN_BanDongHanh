import 'package:supabase_flutter/supabase_flutter.dart';

class BlockedUser {
  final String id;
  final String nickname;
  final String? avatarUrl;

  const BlockedUser({
    required this.id,
    required this.nickname,
    this.avatarUrl,
  });
}

class BlockService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> blockUser(String targetId) async {
    final user = _client.auth.currentUser;
    if (user == null || targetId.isEmpty || targetId == user.id) return;
    try {
      await _client.from('blocks').insert({
        'blocker_id': user.id,
        'blocked_id': targetId,
      });
    } on PostgrestException catch (e) {
      // 23505 = unique violation (đã chặn rồi) → bỏ qua
      if (e.code != '23505') rethrow;
    }
  }

  Future<void> unblockUser(String targetId) async {
    final user = _client.auth.currentUser;
    if (user == null || targetId.isEmpty) return;
    await _client
        .from('blocks')
        .delete()
        .eq('blocker_id', user.id)
        .eq('blocked_id', targetId);
  }

  Future<bool> isBlocked(String targetId) async {
    final user = _client.auth.currentUser;
    if (user == null || targetId.isEmpty) return false;
    try {
      final row = await _client
          .from('blocks')
          .select('id')
          .eq('blocker_id', user.id)
          .eq('blocked_id', targetId)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<BlockedUser>> getBlockedUsers() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    try {
      final blockRows = await _client
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', user.id)
          .order('created_at', ascending: false);

      final ids = (blockRows as List)
          .map((r) => (r as Map<String, dynamic>)['blocked_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (ids.isEmpty) return [];

      final profileRows = await _client
          .from('profiles')
          .select('id, nickname, avatar_url')
          .inFilter('id', ids);

      final profileMap = {
        for (final p in profileRows as List)
          (p as Map<String, dynamic>)['id'].toString(): p,
      };

      // Giữ thứ tự theo blocked (mới nhất trước)
      return ids.map((id) {
        final p = profileMap[id];
        return BlockedUser(
          id: id,
          nickname: p?['nickname']?.toString() ?? 'Người dùng',
          avatarUrl: p?['avatar_url']?.toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> countBlocked() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final rows = await _client
          .from('blocks')
          .select('id')
          .eq('blocker_id', user.id);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }
}
