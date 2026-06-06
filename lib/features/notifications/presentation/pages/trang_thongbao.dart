import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/notification_service.dart';

// ---------- data model ----------

class _NotifGroup {
  final String type;
  final List<NotificationItem> items;

  _NotifGroup(this.type, this.items);

  bool get hasUnread => items.any((e) => !e.isRead);
  DateTime? get latestTime => items.isEmpty ? null : items.first.createdAt;
  int? get latestReferenceId => items.isEmpty ? null : items.first.referenceId;
  List<int> get allIds => items.map((e) => e.id).toList();

  String get _firstName =>
      items.first.title.trim().isNotEmpty ? items.first.title.trim() : 'Ai đó';

  String get _secondName => items.length > 1 && items[1].title.trim().isNotEmpty
      ? items[1].title.trim()
      : '';

  String get _actionText {
    switch (type) {
      case 'follow':
        return 'đã theo dõi bạn';
      case 'like':
        return 'đã thích bài viết của bạn';
      case 'comment':
        return 'đã bình luận bài viết của bạn';
      case 'moment_reply':
        // content lưu action text, title lưu tên người gửi
        return items.first.content.isNotEmpty
            ? items.first.content
            : 'đã trả lời khoảnh khắc của bạn';
      case 'place_share':
        return items.first.content.isNotEmpty
            ? items.first.content
            : 'đã chia sẻ địa điểm cho bạn';
      case 'itinerary_reminder':
        return items.first.content.isNotEmpty
            ? items.first.content
            : 'nhắc lịch trình của bạn';
      case 'group_itinerary_reminder':
        return items.first.content.isNotEmpty
            ? items.first.content
            : 'nhắc lịch trình nhóm của bạn';
      case 'group_trip_member_added':
        return items.first.content.isNotEmpty
            ? items.first.content
            : 'đã thêm bạn vào lịch trình nhóm';
      default:
        return items.first.content;
    }
  }

  // Returns rich-text spans: [boldActors, normalAction]
  (String actors, String action) get displayParts {
    final count = items.length;
    final action = _actionText;
    if (count == 1) return (_firstName, ' $action');
    if (count == 2 && _secondName.isNotEmpty) {
      return ('$_firstName và $_secondName', ' $action');
    }
    return ('$_firstName và ${count - 1} người nữa', ' $action');
  }

  String get timeText => items.isEmpty ? '' : items.first.timeText;

  IconData get icon {
    switch (type) {
      case 'follow':
        return LucideIcons.userPlus;
      case 'like':
        return LucideIcons.heart;
      case 'comment':
        return LucideIcons.messageCircle;
      case 'moment_reply':
        return LucideIcons.camera;
      case 'place_share':
        return LucideIcons.mapPin;
      case 'group_trip_member_added':
        return LucideIcons.users;
      case 'itinerary_reminder':
      case 'group_itinerary_reminder':
        return Icons.event_available_rounded;
      default:
        return LucideIcons.bell;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'follow':
        return const Color(0xFF4AA8FF);
      case 'like':
        return Colors.pinkAccent;
      case 'comment':
        return Colors.greenAccent;
      case 'moment_reply':
        return Colors.orangeAccent;
      case 'place_share':
        return const Color(0xFF4AA8FF);
      case 'group_trip_member_added':
        return const Color(0xFF4AA8FF);
      case 'itinerary_reminder':
      case 'group_itinerary_reminder':
        return Colors.amberAccent;
      default:
        return Colors.white70;
    }
  }
}

List<_NotifGroup> _groupNotifications(List<NotificationItem> items) {
  final map = <String, List<NotificationItem>>{};
  for (final item in items) {
    // like/comment: group theo từng bài viết riêng (type_postId)
    // các loại khác: group theo type
    final shouldGroupByReference =
        item.type == 'like' ||
        item.type == 'comment' ||
        item.type == 'place_share' ||
        item.type == 'itinerary_reminder' ||
        item.type == 'group_itinerary_reminder' ||
        item.type == 'group_trip_member_added';

    final key = shouldGroupByReference
        ? '${item.type}_${item.referenceId ?? 0}'
        : item.type;
    map.putIfAbsent(key, () => []).add(item);
  }
  return map.entries.map((e) {
    // Dedup: giữ lại thông báo mới nhất của mỗi actor (title)
    final seen = <String>{};
    final deduped = e.value.where((item) {
      final actorKey = item.title.trim().toLowerCase();
      if (actorKey.isEmpty) return true;
      return seen.add(actorKey);
    }).toList();
    return _NotifGroup(e.value.first.type, deduped);
  }).toList()..sort(
    (a, b) =>
        (b.latestTime ?? DateTime(0)).compareTo(a.latestTime ?? DateTime(0)),
  );
}

// ---------- page ----------

class TrangThongBaoPage extends StatefulWidget {
  const TrangThongBaoPage({super.key});

  @override
  State<TrangThongBaoPage> createState() => _TrangThongBaoPageState();
}

class _TrangThongBaoPageState extends State<TrangThongBaoPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const String fontFamily = 'Inter';

  final NotificationService _service = NotificationService();
  late Future<List<NotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadMine();
  }

  Future<void> _reload() async {
    final future = _service.loadMine();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(context),
            Expanded(
              child: FutureBuilder<List<NotificationItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _emptyState(
                      title: 'Không tải được thông báo',
                      message: snapshot.error.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                      actionText: 'Tải lại',
                      onAction: _reload,
                    );
                  }

                  final all = snapshot.data ?? const [];
                  final groups = _groupNotifications(all);

                  if (groups.isEmpty) {
                    return _emptyState(
                      title: 'Chưa có thông báo',
                      message:
                          'Khi có người theo dõi bạn, thông báo sẽ hiện ở đây.',
                      actionText: 'Tải lại',
                      onAction: _reload,
                    );
                  }

                  return RefreshIndicator(
                    color: blue,
                    backgroundColor: const Color(0xFF1C1C1E),
                    onRefresh: _reload,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      itemCount: groups.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Gần đây',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return _groupCard(groups[index - 1]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.chevronLeft,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Thông báo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _groupCard(_NotifGroup group) {
    final (actors, action) = group.displayParts;
    final isUnread = group.hasUnread;

    return InkWell(
      onTap: () async {
        await _service.markGroupAsRead(group.allIds);
        if (!mounted) return;

        switch (group.type) {
          case 'follow':
            final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
            Navigator.pushNamed(
              context,
              AppRoutes.profileConnections,
              arguments: {'targetUserId': userId, 'type': 'followers'},
            );
          case 'moment_reply':
            if ((group.latestReferenceId ?? 0) > 0) {
              final senderName = group.items.first.title.trim().isNotEmpty
                  ? group.items.first.title.trim()
                  : 'Tin nhắn';
              Navigator.pushNamed(
                context,
                AppRoutes.chatDetail,
                arguments: {
                  'conversationId': group.latestReferenceId,
                  'name': senderName,
                  'isWaiting': false,
                },
              );
            }
          case 'like':
          case 'comment':
          case 'tag':
            if ((group.latestReferenceId ?? 0) > 0) {
              Navigator.pushNamed(
                context,
                AppRoutes.trangBinhLuan,
                arguments: group.latestReferenceId,
              );
            } else {
              _reload();
            }
          case 'message':
            Navigator.pushNamed(context, AppRoutes.messages);
          case 'place_share':
            if ((group.latestReferenceId ?? 0) > 0) {
              Navigator.pushNamed(
                context,
                AppRoutes.placeDetail,
                arguments: group.latestReferenceId,
              );
            } else {
              _reload();
            }
          case 'itinerary_reminder':
            if ((group.latestReferenceId ?? 0) > 0) {
              Navigator.pushNamed(
                context,
                AppRoutes.tripDetail,
                arguments: {'itineraryId': group.latestReferenceId},
              );
            } else {
              Navigator.pushNamed(context, AppRoutes.tripList);
            }
          case 'group_itinerary_reminder':
          case 'group_trip_member_added':
            if ((group.latestReferenceId ?? 0) > 0) {
              Navigator.pushNamed(
                context,
                AppRoutes.groupTripDetail,
                arguments: {'tripId': group.latestReferenceId},
              );
            } else {
              Navigator.pushNamed(context, AppRoutes.tripList);
            }
          default:
            _reload();
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar circle + type icon badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: group.iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: group.iconColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(group.icon, color: group.iconColor, size: 20),
                ),
                if (group.items.length > 1)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Text(
                        '${group.items.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text: actors,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: action),
                    if (group.timeText.isNotEmpty)
                      TextSpan(
                        text: '  ${group.timeText}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Unread dot
            if (isUnread) ...[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: blue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return RefreshIndicator(
      color: blue,
      backgroundColor: const Color(0xFF1C1C1E),
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onAction, child: Text(actionText)),
        ],
      ),
    );
  }
}
