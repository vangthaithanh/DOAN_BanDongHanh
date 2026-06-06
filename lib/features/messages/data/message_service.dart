import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/time_ago.dart';

enum RealMessageType {
  text,
  location,
  image,
  video,
  audio,
  sticker,
  place,
  post,
  momentReply,
}

class ConversationPreview {
  final int conversationId;
  final String otherProfileId;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final String timeText;
  final int unreadCount;
  final bool isWaiting;
  final DateTime? lastMessageAt;

  const ConversationPreview({
    required this.conversationId,
    required this.otherProfileId,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.timeText,
    required this.unreadCount,
    required this.isWaiting,
    this.lastMessageAt,
  });

  bool get isUnread => unreadCount > 0;
}

class RealMessage {
  final int id;
  final int conversationId;
  final String senderProfileId;
  final String text;
  final RealMessageType type;
  final DateTime? createdAt;
  final bool isMe;
  final String? mediaUrl;
  final int? momentId;
  final int? postId;

  const RealMessage({
    required this.id,
    required this.conversationId,
    required this.senderProfileId,
    required this.text,
    required this.type,
    this.createdAt,
    required this.isMe,
    this.mediaUrl,
    this.momentId,
    this.postId,
  });
}

class MessageService {
  final SupabaseClient _client = Supabase.instance.client;

  static final Set<int> _deletedMessageIds = {};
  static final Set<int> _deletedConversationIds = {};

  Future<List<ConversationPreview>> loadConversations({
    required bool waiting,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final memberships = await _client
        .from('conversation_members')
        .select('conversation_id, last_read_at, status, hidden_at')
        .eq('profile_id', user.id)
        .eq('status', 'active');

    final previews = <ConversationPreview>[];

    for (final raw in memberships as List) {
      final membership = raw as Map<String, dynamic>;
      final conversationId = _asInt(membership['conversation_id']);
      final String? hiddenAtStr = membership['hidden_at']?.toString();

      if (conversationId == 0) continue;

      final conversation = await _loadConversation(conversationId);
      if (conversation == null ||
          conversation['conversation_type']?.toString() != 'private' ||
          conversation['status']?.toString() == 'deleted') {
        continue;
      }

      final otherProfile = await _loadOtherProfile(conversationId, user.id);
      if (otherProfile == null) continue;

      final otherProfileId = otherProfile['id']?.toString() ?? '';
      final isMutual = await _isMutualFollow(user.id, otherProfileId);
      final isWaiting = !isMutual;

      if (isWaiting != waiting) continue;

      final lastMessage = await _loadLastMessage(
        conversationId,
        hiddenAt: hiddenAtStr,
      );
      final lastReadAt = DateTime.tryParse(
        membership['last_read_at']?.toString() ?? '',
      )?.toLocal();

      final unreadCount = await _countUnread(
        conversationId: conversationId,
        currentUserId: user.id,
        lastReadAt: lastReadAt,
        hiddenAt: hiddenAtStr,
      );

      previews.add(
        ConversationPreview(
          conversationId: conversationId,
          otherProfileId: otherProfileId,
          name: _displayName(otherProfile),
          avatarUrl: _emptyToNull(otherProfile['avatar_url']),
          lastMessage: _messagePreview(lastMessage),
          timeText: _timeText(lastMessage?['sent_at']),
          unreadCount: unreadCount,
          isWaiting: isWaiting,
          lastMessageAt: DateTime.tryParse(
            lastMessage?['sent_at']?.toString() ?? '',
          )?.toLocal(),
        ),
      );
    }

    previews.sort(
      (a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(
        a.lastMessageAt ?? DateTime(0),
      ),
    );

    return previews
        .where((p) => !_deletedConversationIds.contains(p.conversationId))
        .toList();
  }

  Future<int> countUnreadNormal() async {
    try {
      final conversations = await loadConversations(waiting: false);
      return conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);
    } catch (_) {
      return 0;
    }
  }

  Future<int> countUnreadAll() async {
    try {
      final normal = await loadConversations(waiting: false);
      final waiting = await loadConversations(waiting: true);
      return [
        ...normal,
        ...waiting,
      ].fold<int>(0, (sum, item) => sum + item.unreadCount);
    } catch (_) {
      return 0;
    }
  }

  Future<List<RealMessage>> loadMessages(int conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    // 1. Lấy mốc hidden_at chính xác
    final membership = await _client
        .from('conversation_members')
        .select('hidden_at')
        .eq('conversation_id', conversationId)
        .eq('profile_id', user.id)
        .maybeSingle();

    final String? hiddenAtStr = membership?['hidden_at']?.toString();
    final DateTime? hiddenAtDate =
        (hiddenAtStr != null && hiddenAtStr != 'null' && hiddenAtStr.isNotEmpty)
        ? DateTime.tryParse(hiddenAtStr.replaceFirst(' ', 'T'))
        : null;

    // 2. Query tin nhắn
    var query = _client
        .from('messages')
        .select(
          'id, conversation_id, sender_profile_id, message_type, content, sent_at, media_url, moment_id, post_id',
        )
        .eq('conversation_id', conversationId);

    // Lọc sơ bộ ở DB
    if (hiddenAtStr != null && hiddenAtStr != 'null') {
      query = query.gt('sent_at', hiddenAtStr);
    }

    final rows = await query.order('sent_at', ascending: true);
    await markConversationRead(conversationId);

    // 3. Lọc chính xác tuyệt đối bằng Dart
    return (rows as List)
        .map((raw) {
          final senderId = raw['sender_profile_id']?.toString() ?? '';
          final sentAt = DateTime.tryParse(raw['sent_at']?.toString() ?? '');

          return RealMessage(
            id: _asInt(raw['id']),
            conversationId: _asInt(raw['conversation_id']),
            senderProfileId: senderId,
            text: raw['content']?.toString() ?? '',
            type: _messageType(raw['message_type']),
            createdAt: sentAt?.toLocal(),
            isMe: senderId == user.id,
            mediaUrl: raw['media_url']?.toString(),
            momentId: raw['moment_id'] != null
                ? _asInt(raw['moment_id'])
                : null,
            postId: raw['post_id'] != null ? _asInt(raw['post_id']) : null,
          );
        })
        .where((m) {
          if (_deletedMessageIds.contains(m.id)) return false;
          if (hiddenAtDate != null && m.createdAt != null) {
            // So sánh UTC để đảm bảo Messenger logic hoạt động đúng
            return m.createdAt!.toUtc().isAfter(hiddenAtDate.toUtc());
          }
          return true;
        })
        .toList();
  }

  Future<void> deleteConversation(int conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null || conversationId == 0) return;
    _deletedConversationIds.add(conversationId);
    try {
      final res = await _client
          .from('conversation_members')
          .update({
        'status': 'deleted',
        'hidden_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('conversation_id', conversationId)
          .eq('profile_id', user.id)
          .select(); // ← thêm .select() để xem rows affected

      print('🗑️ deleteConversation result: $res'); // xem có update được không
    } catch (e) {
      print('❌ deleteConversation error: $e');
    } catch (_) {}

    try {
      await _client
          .from('notifications')
          .delete()
          .eq('profile_id', user.id)
          .inFilter('notification_type', ['moment_reply', 'message'])
          .eq('reference_id', conversationId);
    } catch (_) {}
  }

  Future<void> _reactivateConversation(int conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      // Kiểm tra xem conversation có đang bị deleted không
      final membership = await _client
          .from('conversation_members')
          .select('status, hidden_at')
          .eq('conversation_id', conversationId)
          .eq('profile_id', user.id)
          .maybeSingle();

      if (membership == null) return;

      final isDeleted = membership['status']?.toString() == 'deleted';

      await _client
          .from('conversation_members')
          .update({
        'status': 'active',
        // Nếu đang deleted thì cập nhật hidden_at = now
        // để ẩn toàn bộ tin nhắn cũ trước khi xóa
        if (isDeleted)
          'hidden_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('conversation_id', conversationId)
          .eq('profile_id', user.id);

      _deletedConversationIds.remove(conversationId);
    } catch (_) {}
  }

  Future<RealMessage> sendText({
    required int conversationId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');
    final text = content.trim();
    if (text.isEmpty) throw Exception('Vui lòng nhập tin nhắn');

    final row = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_profile_id': user.id,
          'message_type': 'text',
          'content': text,
        })
        .select(
          'id, conversation_id, sender_profile_id, message_type, content, sent_at',
        )
        .single();

    await _reactivateConversation(conversationId);
    await markConversationRead(conversationId);

    return RealMessage(
      id: _asInt(row['id']),
      conversationId: _asInt(row['conversation_id']),
      senderProfileId: user.id,
      text: row['content']?.toString() ?? text,
      type: RealMessageType.text,
      createdAt: DateTime.tryParse(row['sent_at']?.toString() ?? '')?.toLocal(),
      isMe: true,
    );
  }

  Future<int> sendMomentReply({
    required String momentOwnerProfileId,
    required String replyText,
    required int momentId,
    required String momentImageUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');
    final conversationId = await openPrivateConversation(momentOwnerProfileId);
    final content = replyText.trim().isNotEmpty
        ? replyText.trim()
        : '📸 Đã trả lời khoảnh khắc của bạn';

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_profile_id': user.id,
      'message_type': 'moment_reply',
      'moment_id': momentId,
      'content': content,
      'media_url': momentImageUrl,
    });
    await _reactivateConversation(conversationId);
    return conversationId;
  }

  Future<void> sendSharedPost({
    required int conversationId,
    required int postId,
    String caption = '',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_profile_id': user.id,
      'message_type': 'post',
      'post_id': postId,
      'content': caption.trim(),
    });
    await _reactivateConversation(conversationId);
    await markConversationRead(conversationId);
  }

  Future<int> sharePostToFriends({
    required int postId,
    required List<String> friendProfileIds,
    String caption = '',
  }) async {
    int success = 0;
    for (final friendId in friendProfileIds) {
      try {
        final convId = await openPrivateConversation(friendId);
        await sendSharedPost(
          conversationId: convId,
          postId: postId,
          caption: caption,
        );
        success++;
      } catch (_) {}
    }
    return success;
  }

  Future<int> openPrivateConversation(String otherProfileId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');
    final result = await _client.rpc(
      'get_or_create_private_conversation',
      params: {'p_other_profile_id': otherProfileId},
    );
    final conversationId = _asInt(result);
    await _reactivateConversation(conversationId);
    return conversationId;
  }

  Future<void> acceptWaitingConversation(String otherProfileId) async {
    final user = _client.auth.currentUser;
    if (user == null || otherProfileId.isEmpty || otherProfileId == user.id)
      return;
    final isFollowing = await _isFollowing(user.id, otherProfileId);
    if (!isFollowing) {
      await _client.from('follows').upsert({
        'follower_id': user.id,
        'following_id': otherProfileId,
        'status': 'active',
      }, onConflict: 'follower_id,following_id');
    }
  }

  Future<DateTime?> getOtherMemberLastRead(int conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final row = await _client
          .from('conversation_members')
          .select('last_read_at')
          .eq('conversation_id', conversationId)
          .neq('profile_id', user.id)
          .eq('status', 'active')
          .maybeSingle();
      return DateTime.tryParse(
        row?['last_read_at']?.toString() ?? '',
      )?.toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteMessage(int messageId) async {
    final user = _client.auth.currentUser;
    if (user == null || messageId == 0) return;
    _deletedMessageIds.add(messageId);
    try {
      await _client
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_profile_id', user.id);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _loadLastMessage(
    int conversationId, {
    String? hiddenAt,
  }) async {
    var query = _client
        .from('messages')
        .select('id, sender_profile_id, message_type, content, sent_at')
        .eq('conversation_id', conversationId);
    if (hiddenAt != null && hiddenAt != 'null' && hiddenAt.isNotEmpty) {
      query = query.gt('sent_at', hiddenAt);
    }
    return await query
        .order('sent_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  Future<int> _countUnread({
    required int conversationId,
    required String currentUserId,
    required DateTime? lastReadAt,
    String? hiddenAt,
  }) async {
    var query = _client
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('sender_profile_id', currentUserId);
    if (lastReadAt != null)
      query = query.gt('sent_at', lastReadAt.toUtc().toIso8601String());
    if (hiddenAt != null && hiddenAt != 'null' && hiddenAt.isNotEmpty)
      query = query.gt('sent_at', hiddenAt);
    final rows = await query;
    return (rows as List).length;
  }

  Future<void> markConversationRead(int conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null || conversationId == 0) return;
    await _client
        .from('conversation_members')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('profile_id', user.id);
  }

  Future<Map<String, dynamic>?> _loadConversation(int id) async => await _client
      .from('conversations')
      .select('id, conversation_type, status')
      .eq('id', id)
      .maybeSingle();

  Future<Map<String, dynamic>?> _loadOtherProfile(
      int convId,
      String userId,
      ) async {
    final other = await _client
        .from('conversation_members')
        .select('profile_id')
        .eq('conversation_id', convId)
        .neq('profile_id', userId)
        .limit(1)
        .maybeSingle();
    if (other == null) return null;
    return _client
        .from('profiles')
        .select('id, nickname, full_name, email, avatar_url')
        .eq('id', other['profile_id'])
        .maybeSingle();
  }

  Future<bool> _isMutualFollow(String u1, String u2) async =>
      await _isFollowing(u1, u2) && await _isFollowing(u2, u1);

  Future<bool> _isFollowing(String f1, String f2) async {
    try {
      final row = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', f1)
          .eq('following_id', f2)
          .eq('status', 'active')
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  String _displayName(Map<String, dynamic> p) =>
      p['nickname'] ?? p['full_name'] ?? 'Người dùng';

  String _messagePreview(Map<String, dynamic>? r) {
    if (r == null) return 'Chưa có tin nhắn';
    switch (r['message_type']?.toString()) {
      case 'image':
        return 'Hình ảnh';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Tin nhắn thoại';
      case 'post':
        return 'Bài viết';
      default:
        return r['content']?.toString() ?? 'Tin nhắn';
    }
  }

  String _timeText(dynamic v) {
    final dt = DateTime.tryParse(v?.toString() ?? '');
    return dt == null ? '' : timeAgo(dt.toLocal());
  }

  RealMessageType _messageType(dynamic v) {
    switch (v?.toString()) {
      case 'image':
        return RealMessageType.image;
      case 'video':
        return RealMessageType.video;
      case 'audio':
        return RealMessageType.audio;
      case 'location':
        return RealMessageType.location;
      case 'sticker':
        return RealMessageType.sticker;
      case 'place':
        return RealMessageType.place;
      case 'post':
        return RealMessageType.post;
      case 'moment_reply':
        return RealMessageType.momentReply;
      default:
        return RealMessageType.text;
    }
  }

  String? _emptyToNull(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
