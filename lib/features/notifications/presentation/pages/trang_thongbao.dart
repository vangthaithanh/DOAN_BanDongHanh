import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/notification_service.dart';

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

    setState(() {
      _future = future;
    });

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
                    return _messageState(
                      title: 'Không tải được thông báo',
                      message: snapshot.error.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                      actionText: 'Tải lại',
                      onAction: _reload,
                    );
                  }

                  final notifications = snapshot.data ?? const [];

                  if (notifications.isEmpty) {
                    return _messageState(
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
                      itemCount: notifications.length + 1,
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

                        return _notificationItem(notifications[index - 1]);
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

  Widget _notificationItem(NotificationItem data) {
    final isUnread = !data.isRead;

    return InkWell(
      onTap: () async {
        await _service.markAsRead(data.id);
        if (!mounted) return;

        if (data.type == 'moment_reply' && (data.referenceId ?? 0) > 0) {
          Navigator.pushNamed(
            context,
            AppRoutes.chatDetail,
            arguments: {
              'conversationId': data.referenceId,
              'name': 'Tin nhắn',
              'isWaiting': false,
            },
          );
        } else {
          _reload();
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(radius: 20, backgroundColor: blue),
                if (data.type == 'follow')
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.black,
                      child: Icon(LucideIcons.userPlus, color: blue, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(
                      text: data.title.isEmpty ? 'Người dùng' : data.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' ${data.content}'),
                    if (data.timeText.isNotEmpty)
                      TextSpan(
                        text: '  ${data.timeText}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
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

  Widget _messageState({
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
