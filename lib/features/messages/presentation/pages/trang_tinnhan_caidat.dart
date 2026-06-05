import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/routes/app_routes.dart';
import '../../data/message_service.dart';
import '../../data/mock/mock_messages.dart';
import '../../../users/presentation/pages/trang_hoso_nguoidung.dart';

class TrangTinNhanCaiDatPage extends StatefulWidget {

  final String name;
  final bool isWaiting;
  final String? otherProfileId;
  final int? conversationId;
  const TrangTinNhanCaiDatPage({
    super.key,
    required this.name,
    required this.isWaiting,
    this.otherProfileId,
    this.conversationId,
  });

  @override
  State<TrangTinNhanCaiDatPage> createState() =>
      _TrangTinNhanCaiDatPageState();
}

class _TrangTinNhanCaiDatPageState
    extends State<TrangTinNhanCaiDatPage> {

  static const Color blue = Color(0xFF4AA8FF);

  String _nickname = '';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final prefs =
    await SharedPreferences.getInstance();

    setState(() {
      _nickname =
          prefs.getString(
            'nickname_${widget.name}',
          ) ??
              widget.name;

      nicknames[widget.name] = _nickname;
    });
  }

  Future<void> _saveNickname(
      String nickname) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      'nickname_${widget.name}',
      nickname,
    );

    nicknames[widget.name] = nickname;

    setState(() {
      _nickname = nickname;
    });
  }

  Future<void> _editNickname() async {
    final controller =
    TextEditingController(
      text: _nickname,
    );

    final result =
    await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor:
          const Color(0xFF2C2C2E),
          title: const Text(
            'Đổi biệt danh',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    controller.text.trim(),
                  ),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (result != null &&
        result.isNotEmpty) {
      await _saveNickname(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaMessages =
        allChatsData[widget.name]
            ?.where(
              (e) =>
          e.type == MessageType.image ||
              e.type == MessageType.video,
        )
            .toList() ??
            [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            /// Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            /// Avatar
            const CircleAvatar(
              radius: 34,
              backgroundColor: blue,
            ),

            const SizedBox(height: 16),

            /// Nickname
            Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  _nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 8),

                InkWell(
                  onTap: _editNickname,
                  child: const Icon(
                    LucideIcons.penLine,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            const Text(
              'Họ tên',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 28),

            /// Top actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _topAction(
                  icon: LucideIcons.user,
                  label: 'Trang cá nhân',
                  onTap: () {
                    if (widget.otherProfileId != null) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.profile,
                        arguments: widget.otherProfileId,
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration:
                        const Duration(milliseconds: 350),
                        pageBuilder:
                            (_, animation, secondaryAnimation) =>
                            TrangHoSoNguoiDungPage(
                              userName: widget.name,
                              isFollowing: !widget.isWaiting,
                            ),
                        transitionsBuilder:
                            (_, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOutCubic,
                              ),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
                _topAction(
                  icon: LucideIcons.search,
                  label: 'Tìm kiếm',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _menuItem(
                    icon: LucideIcons.userPlus,
                    title: 'Tạo nhóm chat',
                    onTap: () {},
                  ),
                  _menuItem(
                    icon: LucideIcons.ban,
                    title: 'Chặn',
                    onTap: () {},
                  ),
                  _menuItem(
                    icon: LucideIcons.shieldAlert,
                    title: 'Báo cáo',
                    onTap: () {},
                  ),
                  _menuItem(
                    icon: Icons.delete_outline,
                    title: 'Xóa đoạn chat',
                    color: Colors.redAccent,
                    onTap: () => _xoaDoanChat(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Divider(
              color: Colors.white12,
              height: 1,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: mediaMessages.isEmpty
                    ? const Center(
                  child: Text(
                    'Chưa có ảnh hoặc video',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                )
                    : GridView.builder(
                  itemCount: mediaMessages.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemBuilder: (_, index) {
                    final media = mediaMessages[index];

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _mediaTile(media),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 120,
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _xoaDoanChat(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Xóa đoạn chat',
            style: TextStyle(color: Colors.white)),
        content: const Text('Đoạn chat sẽ bị xóa khỏi danh sách của bạn.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true && widget.conversationId != null) {
      await MessageService().deleteConversation(widget.conversationId!);
      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        child: Row(
          children: [
            Icon(icon, color: c),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: c, fontSize: 15),
              ),
            ),
            Icon(LucideIcons.chevronRight, color: c.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _mediaTile(MessageModel media) {
    if (media.type == MessageType.image) {
      return Image.file(
        File(media.text),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: Colors.white10,
            child: const Icon(
              Icons.image,
              color: Colors.white54,
            ),
          );
        },
      );
    }

    if (media.type == MessageType.video) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.white10,
          ),
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
