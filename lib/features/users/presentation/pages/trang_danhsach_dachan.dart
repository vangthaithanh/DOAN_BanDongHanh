import 'package:flutter/material.dart';

import '../../data/block_service.dart';

class TrangDanhSachDaChanPage extends StatefulWidget {
  const TrangDanhSachDaChanPage({super.key});

  @override
  State<TrangDanhSachDaChanPage> createState() =>
      _TrangDanhSachDaChanPageState();
}

class _TrangDanhSachDaChanPageState extends State<TrangDanhSachDaChanPage> {
  static const Color blue = Color(0xFF4AA8FF);

  final BlockService _service = BlockService();
  late Future<List<BlockedUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getBlockedUsers();
  }

  void _reload() => setState(() => _future = _service.getBlockedUsers());

  Future<void> _unblock(BlockedUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Bỏ chặn', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bỏ chặn ${user.nickname}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bỏ chặn',
                style: TextStyle(color: blue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _service.unblockUser(user.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Đã chặn',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<BlockedUser>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: blue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không tải được',
                      style: TextStyle(color: Colors.white70)),
                  TextButton(onPressed: _reload, child: const Text('Thử lại')),
                ],
              ),
            );
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return const Center(
              child: Text(
                'Chưa chặn ai',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final user = list[index];
              return _userTile(user);
            },
          );
        },
      ),
    );
  }

  Widget _userTile(BlockedUser user) {
    final hasAvatar =
        user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: blue,
            backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl!) : null,
            child: hasAvatar
                ? null
                : Text(
                    user.nickname.isEmpty ? '?' : user.nickname[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              user.nickname,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _unblock(user),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Bỏ chặn',
              style: TextStyle(
                color: blue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
