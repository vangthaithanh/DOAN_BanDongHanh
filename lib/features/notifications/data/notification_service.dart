import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/time_ago.dart';

class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String content;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.isRead,
    this.createdAt,
  });

  String get timeText {
    final date = createdAt;

    if (date == null) {
      return '';
    }

    return timeAgo(date);
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['created_at']?.toString().trim() ?? '';

    return NotificationItem(
      id: _asInt(map['id']),
      type: map['notification_type']?.toString() ?? '',
      title: map['title']?.toString().trim() ?? '',
      content: map['content']?.toString().trim() ?? '',
      isRead: map['is_read'] == true,
      createdAt: DateTime.tryParse(rawCreatedAt)?.toLocal(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<NotificationItem>> loadMine() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final rows = await _client
        .from('notifications')
        .select('id, notification_type, title, content, is_read, created_at')
        .eq('profile_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((raw) => NotificationItem.fromMap(raw as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(int notificationId) async {
    final user = _client.auth.currentUser;

    if (user == null || notificationId == 0) {
      return;
    }

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('profile_id', user.id);
  }
}
