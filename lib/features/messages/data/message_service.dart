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

  const ConversationPreview({
    required this.conversationId,
    required this.otherProfileId,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.timeText,
    required this.unreadCount,
    required this.isWaiting,
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

  const RealMessage({
    required this.id,
    required this.conversationId,
    required this.senderProfileId,
    required this.text,
    required this.type,
    this.createdAt,
    required this.isMe,
  });
}

class MessageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ConversationPreview>> loadConversations({
    required bool waiting,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final memberships = await _client
        .from('conversation_members')
        .select('conversation_id, last_read_at, status')
        .eq('profile_id', user.id)
        .eq('status', 'active');

    final previews = <ConversationPreview>[];

    for (final raw in memberships as List) {
      final membership = raw as Map<String, dynamic>;
      final conversationId = _asInt(membership['conversation_id']);

      if (conversationId == 0) {
        continue;
      }

      final conversation = await _loadConversation(conversationId);

      if (conversation == null ||
          conversation['conversation_type']?.toString() != 'private' ||
          conversation['status']?.toString() == 'deleted') {
        continue;
      }

      final otherProfile = await _loadOtherProfile(conversationId, user.id);

      if (otherProfile == null) {
        continue;
      }

      final otherProfileId = otherProfile['id']?.toString() ?? '';
      final isMutual = await _isMutualFollow(user.id, otherProfileId);
      final isWaiting = !isMutual;

      if (isWaiting != waiting) {
        continue;
      }

      final lastMessage = await _loadLastMessage(conversationId);
      final lastReadAt = DateTime.tryParse(
        membership['last_read_at']?.toString() ?? '',
      )?.toLocal();
      final unreadCount = await _countUnread(
        conversationId: conversationId,
        currentUserId: user.id,
        lastReadAt: lastReadAt,
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
        ),
      );
    }

    previews.sort((a, b) => b.conversationId.compareTo(a.conversationId));

    return previews;
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

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final rows = await _client
        .from('messages')
        .select(
          'id, conversation_id, sender_profile_id, message_type, content, sent_at',
        )
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: true);

    await markConversationRead(conversationId);

    return (rows as List).map((raw) {
      final row = raw as Map<String, dynamic>;
      final senderId = row['sender_profile_id']?.toString() ?? '';

      return RealMessage(
        id: _asInt(row['id']),
        conversationId: _asInt(row['conversation_id']),
        senderProfileId: senderId,
        text: row['content']?.toString() ?? '',
        type: _messageType(row['message_type']),
        createdAt: DateTime.tryParse(
          row['sent_at']?.toString() ?? '',
        )?.toLocal(),
        isMe: senderId == user.id,
      );
    }).toList();
  }

  Future<RealMessage> sendText({
    required int conversationId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final text = content.trim();

    if (text.isEmpty) {
      throw Exception('Vui lòng nhập tin nhắn');
    }

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

  Future<int> openPrivateConversation(String otherProfileId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    if (otherProfileId.trim().isEmpty || otherProfileId == user.id) {
      throw Exception('Không thể mở cuộc trò chuyện');
    }

    final existing = await _findPrivateConversation(user.id, otherProfileId);

    if (existing != null) {
      return existing;
    }

    final conversation = await _client
        .from('conversations')
        .insert({'conversation_type': 'private', 'status': 'active'})
        .select('id')
        .single();
    final conversationId = _asInt(conversation['id']);

    await _client.from('conversation_members').insert([
      {
        'conversation_id': conversationId,
        'profile_id': user.id,
        'role': 'member',
        'status': 'active',
        'last_read_at': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'conversation_id': conversationId,
        'profile_id': otherProfileId,
        'role': 'member',
        'status': 'active',
      },
    ]);

    return conversationId;
  }

  Future<void> acceptWaitingConversation(String otherProfileId) async {
    final user = _client.auth.currentUser;

    if (user == null || otherProfileId.isEmpty || otherProfileId == user.id) {
      return;
    }

    final isFollowing = await _isFollowing(user.id, otherProfileId);

    if (!isFollowing) {
      await _client.from('follows').upsert({
        'follower_id': user.id,
        'following_id': otherProfileId,
        'status': 'active',
      }, onConflict: 'follower_id,following_id');
    }
  }

  Future<void> markConversationRead(int conversationId) async {
    final user = _client.auth.currentUser;

    if (user == null || conversationId == 0) {
      return;
    }

    await _client
        .from('conversation_members')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('profile_id', user.id);
<<<<<<< HEAD

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('profile_id', user.id)
        .eq('notification_type', 'message')
        .eq('is_read', false);
=======
>>>>>>> origin/bui_trong
  }

  Future<int?> _findPrivateConversation(
    String userId,
    String otherProfileId,
  ) async {
    final mine = await _client
        .from('conversation_members')
        .select('conversation_id')
        .eq('profile_id', userId)
        .eq('status', 'active');

    for (final raw in mine as List) {
      final conversationId = _asInt(
        (raw as Map<String, dynamic>)['conversation_id'],
      );

      if (conversationId == 0) {
        continue;
      }

      final other = await _client
          .from('conversation_members')
          .select('conversation_id')
          .eq('conversation_id', conversationId)
          .eq('profile_id', otherProfileId)
          .eq('status', 'active')
          .maybeSingle();

      if (other != null) {
        final conversation = await _loadConversation(conversationId);

        if (conversation?['conversation_type']?.toString() == 'private') {
          return conversationId;
        }
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> _loadConversation(int conversationId) async {
    try {
      return await _client
          .from('conversations')
          .select('id, conversation_type, status')
          .eq('id', conversationId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadOtherProfile(
    int conversationId,
    String currentUserId,
  ) async {
    final otherMember = await _client
        .from('conversation_members')
        .select('profile_id')
        .eq('conversation_id', conversationId)
        .neq('profile_id', currentUserId)
        .eq('status', 'active')
        .limit(1)
        .maybeSingle();

    final otherProfileId = otherMember?['profile_id']?.toString() ?? '';

    if (otherProfileId.isEmpty) {
      return null;
    }

    return _client
        .from('profiles')
        .select('id, nickname, full_name, email, avatar_url')
        .eq('id', otherProfileId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> _loadLastMessage(int conversationId) async {
    try {
      return await _client
          .from('messages')
          .select('id, sender_profile_id, message_type, content, sent_at')
          .eq('conversation_id', conversationId)
          .order('sent_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<int> _countUnread({
    required int conversationId,
    required String currentUserId,
    required DateTime? lastReadAt,
  }) async {
    try {
      var query = _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_profile_id', currentUserId);

      if (lastReadAt != null) {
        query = query.gt('sent_at', lastReadAt.toUtc().toIso8601String());
      }

      final rows = await query;

      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> _isMutualFollow(String userId, String otherProfileId) async {
    final aFollowsB = await _isFollowing(userId, otherProfileId);
    final bFollowsA = await _isFollowing(otherProfileId, userId);

    return aFollowsB && bFollowsA;
  }

  Future<bool> _isFollowing(String followerId, String followingId) async {
    if (followerId.isEmpty || followingId.isEmpty) {
      return false;
    }

    try {
      final row = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .eq('status', 'active')
          .maybeSingle();

      return row != null;
    } catch (_) {
      return false;
    }
  }

  String _displayName(Map<String, dynamic> profile) {
    return _firstText([
      profile['nickname'],
      profile['full_name'],
      profile['email'],
    ], fallback: 'Người dùng');
  }

  String _messagePreview(Map<String, dynamic>? row) {
    if (row == null) {
      return 'Chưa có tin nhắn';
    }

    switch (row['message_type']?.toString()) {
      case 'image':
        return 'Hình ảnh';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Tin nhắn thoại';
      case 'location':
      case 'place':
        return 'Vị trí';
      case 'post':
        return 'Bài viết';
      case 'sticker':
        return 'Sticker';
      default:
        return row['content']?.toString().trim().isNotEmpty == true
            ? row['content'].toString()
            : 'Tin nhắn';
    }
  }

  String _timeText(dynamic value) {
    final createdAt = DateTime.tryParse(value?.toString() ?? '')?.toLocal();

    if (createdAt == null) {
      return '';
    }

    return timeAgo(createdAt);
  }

  RealMessageType _messageType(dynamic value) {
    switch (value?.toString()) {
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
      default:
        return RealMessageType.text;
    }
  }

  String _firstText(List<dynamic> values, {required String fallback}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text.contains('@') ? text.split('@').first : text;
      }
    }

    return fallback;
  }

  String? _emptyToNull(dynamic value) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
