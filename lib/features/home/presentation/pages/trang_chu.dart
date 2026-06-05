import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../features/notifications/data/notification_service.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../../../shared/widgets/gomate_logo.dart';
import '../../../../shared/widgets/unread_badge.dart';
import '../../data/services/home_feed_service.dart';
import '../../../messages/presentation/widgets/share_post_sheet.dart';
import '../../../social/data/models/post_model.dart';
import '../../../social/presentation/widgets/post_card.dart';

/// NOTE SỬA:
/// Trang chủ:
/// - Bài viết lấy từ Supabase view home_recommended_posts/home_public_posts.
/// - Ô chia sẻ lấy tên/avatar user hiện tại.
class TrangChuPage extends StatefulWidget {
  const TrangChuPage({super.key});

  @override
  State<TrangChuPage> createState() => _TrangChuPageState();
}

class _TrangChuPageState extends State<TrangChuPage> {
  final ProfileService _profileService = ProfileService();
  final HomeFeedService _feedService = HomeFeedService();
  final NotificationService _notificationService = NotificationService();

  MyProfile? _profile;
  bool _loadingProfile = true;
  late Future<List<PostModel>> _feedFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = _feedService.loadFeed();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _profileService.loadMine();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = data.profile;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingProfile = false;
      });
    }
  }

  Future<void> _refreshFeed() async {
    final future = _feedService.loadFeed();

    setState(() {
      _feedFuture = future;
    });

    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: FutureBuilder<List<PostModel>>(
                future: _feedFuture,
                builder: (context, snapshot) => _feedBody(context, snapshot),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: MainTab.home),
    );
  }

  Widget _feedBody(
    BuildContext context,
    AsyncSnapshot<List<PostModel>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _feedShell(
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 34),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (snapshot.hasError) {
      return _feedShell(
        children: [
          _feedMessage(
            title: 'Không tải được bài viết',
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            actionText: 'Tải lại',
            onAction: _refreshFeed,
          ),
        ],
      );
    }

    final posts = snapshot.data ?? const [];

    if (posts.isEmpty) {
      return _feedShell(
        children: [
          _feedMessage(
            title: 'Chưa có bài viết',
            message:
                'Khi có bài viết thật trên Supabase, nội dung sẽ hiện ở đây.',
            actionText: 'Tải lại',
            onAction: _refreshFeed,
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: const Color(0xFF1C1C1E),
      onRefresh: _refreshFeed,
      child: ListView.builder(
        itemCount: posts.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const SizedBox(height: 10);
          }

          if (index == 1) {
            return _shareBox(context);
          }

          if (index == 2) {
            return const SizedBox(height: 12);
          }

          final post = posts[index - 3];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == posts.length + 2 ? 20 : 0,
            ),
            child: PostCard(
              post: post,
              onComment: () async {
                final changed = await Navigator.pushNamed(
                  context,
                  AppRoutes.trangBinhLuan,
                  arguments: post.id,
                );

                if (mounted && changed == true) {
                  await _refreshFeed();
                }
              },
              onShare: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SharePostSheet(postId: post.id),
                );
              },
              onPostModified: () {
                _refreshFeed();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _feedShell({required List<Widget> children}) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: const Color(0xFF1C1C1E),
      onRefresh: _refreshFeed,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 10),
          _shareBox(context),
          const SizedBox(height: 12),
          ...children,
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _feedMessage({
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 20),
      child: Column(
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

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          InkWell(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.globalUserSearch),
            child: const Icon(
              LucideIcons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Expanded(child: GoMateLogo()),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
            child: AsyncUnreadBadge(
              loadCount: _notificationService.countUnreadMine,
              child: const Icon(
                LucideIcons.bell,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareBox(BuildContext context) {
    final avatarUrl = _profile?.avatarUrl ?? '';
    final displayName = _profile?.displayName ?? 'Người dùng';

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.createPost);

        if (mounted) {
          _loadProfile();
          await _refreshFeed();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loadingProfile ? 'Đang tải...' : displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Chia sẻ điều gì mới?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
