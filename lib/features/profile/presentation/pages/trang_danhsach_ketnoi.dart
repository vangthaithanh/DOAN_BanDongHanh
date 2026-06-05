import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/services/profile_connection_service.dart';

class TrangDanhSachKetNoi extends StatefulWidget {
  final String targetUserId;
  final String type;

  const TrangDanhSachKetNoi({
    super.key,
    required this.targetUserId,
    required this.type,
  });

  @override
  State<TrangDanhSachKetNoi> createState() => _TrangDanhSachKetNoiState();
}

class _TrangDanhSachKetNoiState extends State<TrangDanhSachKetNoi> {
  final ProfileConnectionService _service = ProfileConnectionService();

  late Future<List<ProfileConnectionUser>> _future;

  bool get isFollowers => widget.type == 'followers';

  String get title => isFollowers ? 'Người theo dõi' : 'Bạn bè';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _service.loadConnections(
      targetUserId: widget.targetUserId,
      type: widget.type,
    );
  }

  Future<void> _reload() async {
    final future = _service.loadConnections(
      targetUserId: widget.targetUserId,
      type: widget.type,
    );

    setState(() {
      _future = future;
    });

    await future;
  }

  void _openProfile(ProfileConnectionUser user) {
    Navigator.pushNamed(context, AppRoutes.profile, arguments: user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: FutureBuilder<List<ProfileConnectionUser>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _message(
                      icon: Icons.error_outline,
                      title: 'Không tải được dữ liệu',
                      message: snapshot.error.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                      actionText: 'Tải lại',
                      onAction: _reload,
                    );
                  }

                  final users = snapshot.data ?? const [];

                  if (users.isEmpty) {
                    return _message(
                      icon: isFollowers
                          ? Icons.person_search_outlined
                          : Icons.people_outline,
                      title: isFollowers
                          ? 'Chưa có người theo dõi'
                          : 'Chưa có bạn bè',
                      message: isFollowers
                          ? 'Danh sách người theo dõi sẽ hiện ở đây.'
                          : 'Bạn bè là những người theo dõi qua lại.',
                      actionText: 'Tải lại',
                      onAction: _reload,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: const Color(0xFF1C1C1E),
                    onRefresh: _reload,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppColors.border,
                        indent: 72,
                      ),
                      itemBuilder: (context, index) {
                        return _userTile(users[index]);
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

  Widget _topBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _userTile(ProfileConnectionUser user) {
    final name = user.fullName.isNotEmpty ? user.fullName : user.nickname;

    final nickname = user.nickname.isNotEmpty
        ? '@${user.nickname}'
        : '@chưa có biệt danh';

    return InkWell(
      onTap: () => _openProfile(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              backgroundImage: user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : null,
              child: user.avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Người dùng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white30, size: 44),
            const SizedBox(height: 14),
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
                color: Colors.white54,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
