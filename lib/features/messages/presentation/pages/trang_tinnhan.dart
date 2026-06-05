import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../features/notifications/data/notification_service.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../../../shared/widgets/unread_badge.dart';
import '../../data/message_service.dart';
import 'trang_tinnhan_cho.dart';

class TrangTinNhanPage extends StatefulWidget {
  const TrangTinNhanPage({super.key});

  @override
  State<TrangTinNhanPage> createState() => _TrangTinNhanPageState();
}

class _TrangTinNhanPageState extends State<TrangTinNhanPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const String fontFamily = 'Inter';

  final MessageService _messageService = MessageService();
  final NotificationService _notificationService = NotificationService();
  late Future<List<ConversationPreview>> _future;
<<<<<<< HEAD
  RealtimeChannel? _messagesChannel;
  int _badgeVersion = 0;
=======
>>>>>>> origin/bui_trong

  @override
  void initState() {
    super.initState();
    _future = _messageService.loadConversations(waiting: false);
<<<<<<< HEAD
    _subscribeRealtime();
  }

  @override
  void dispose() {
    final channel = _messagesChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  void _subscribeRealtime() {
    _messagesChannel = Supabase.instance.client
        .channel('messages-list-normal')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => _reloadSilently(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (_) => _reloadSilently(),
        )
        .subscribe();
=======
>>>>>>> origin/bui_trong
  }

  Future<void> _reload() async {
    final future = _messageService.loadConversations(waiting: false);

    setState(() {
      _future = future;
<<<<<<< HEAD
      _badgeVersion++;
=======
>>>>>>> origin/bui_trong
    });

    await future;
  }

<<<<<<< HEAD
  void _reloadSilently() {
    if (!mounted) {
      return;
    }

    setState(() {
      _future = _messageService.loadConversations(waiting: false);
      _badgeVersion++;
    });
  }

=======
>>>>>>> origin/bui_trong
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            _searchBar(),
            _tabHeader(context),
            Expanded(
              child: FutureBuilder<List<ConversationPreview>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _messageState(
                      title: 'Không tải được tin nhắn',
                      message: snapshot.error.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                      actionText: 'Tải lại',
                      onAction: _reload,
                    );
                  }

                  final conversations = snapshot.data ?? const [];

                  if (conversations.isEmpty) {
                    return _messageState(
                      title: 'Chưa có tin nhắn',
                      message:
                          'Các cuộc trò chuyện mutual follow sẽ hiện ở đây.',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        return _chatCard(context, conversations[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        key: ValueKey('messages_nav_$_badgeVersion'),
        activeTab: MainTab.messages,
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 24),
          const Text(
            'Tin nhắn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          InkWell(
            onTap: () async {
              await Navigator.pushNamed(context, AppRoutes.notifications);
              if (mounted) setState(() {});
            },
            child: AsyncUnreadBadge(
<<<<<<< HEAD
              key: ValueKey('message_top_bell_$_badgeVersion'),
=======
>>>>>>> origin/bui_trong
              loadCount: _notificationService.countUnreadMine,
              child: const Icon(
                LucideIcons.bell,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm Kiếm',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
            prefixIcon: Icon(
              LucideIcons.search,
              color: Colors.white54,
              size: 18,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _tabHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tin nhắn',
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const TrangTinNhanChoPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1, 0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOutCubic;

                        final tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );

              if (mounted) {
                _reload();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                'Tin nhắn đang chờ',
                style: TextStyle(
                  fontFamily: fontFamily,
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatCard(BuildContext context, ConversationPreview chat) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.chatDetail,
          arguments: {
            'conversationId': chat.conversationId,
            'otherProfileId': chat.otherProfileId,
            'name': chat.name,
            'avatarUrl': chat.avatarUrl,
            'isWaiting': false,
          },
        );

        if (mounted) {
          _reload();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: const Color(0xFF333333), width: 1.5),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: blue,
              backgroundImage: chat.avatarUrl?.trim().isNotEmpty == true
                  ? NetworkImage(chat.avatarUrl!)
                  : null,
              child: chat.avatarUrl?.trim().isNotEmpty == true
                  ? null
                  : Text(
                      chat.name.isEmpty ? '?' : chat.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: fontFamily,
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      color: chat.isUnread ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: chat.isUnread
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  chat.timeText,
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                if (chat.isUnread) ...[
                  const SizedBox(width: 8),
                  UnreadBadge(
                    count: chat.unreadCount,
                    child: const SizedBox(width: 16, height: 16),
                  ),
                ],
              ],
            ),
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
        padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
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
