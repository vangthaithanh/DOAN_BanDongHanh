import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
<<<<<<< HEAD
import 'package:supabase_flutter/supabase_flutter.dart';
=======
>>>>>>> origin/bui_trong

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/unread_badge.dart';
import '../../data/message_service.dart';

class TrangTinNhanChoPage extends StatefulWidget {
  const TrangTinNhanChoPage({super.key});

  @override
  State<TrangTinNhanChoPage> createState() => _TrangTinNhanChoPageState();
}

class _TrangTinNhanChoPageState extends State<TrangTinNhanChoPage> {
  static const Color blue = Color(0xFF4AA8FF);

  final MessageService _service = MessageService();
  late Future<List<ConversationPreview>> _future;
<<<<<<< HEAD
  RealtimeChannel? _messagesChannel;
=======
>>>>>>> origin/bui_trong

  @override
  void initState() {
    super.initState();
    _future = _service.loadConversations(waiting: true);
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
        .channel('messages-list-waiting')
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
    final future = _service.loadConversations(waiting: true);

    setState(() {
      _future = future;
    });

    await future;
  }

<<<<<<< HEAD
  void _reloadSilently() {
    if (!mounted) {
      return;
    }

    setState(() {
      _future = _service.loadConversations(waiting: true);
    });
  }

=======
>>>>>>> origin/bui_trong
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tin nhắn đang chờ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<ConversationPreview>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _messageState(
              title: 'Không tải được tin nhắn chờ',
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
              title: 'Không có tin nhắn chờ',
              message:
                  'Tin nhắn từ người chưa mutual follow sẽ được gom vào đây.',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                return _chatCard(context, conversations[index]);
              },
            ),
          );
        },
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
            'isWaiting': true,
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
          border: Border.all(color: const Color(0xFF222222), width: 1.5),
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
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  chat.timeText,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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
        padding: const EdgeInsets.fromLTRB(24, 90, 24, 20),
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
