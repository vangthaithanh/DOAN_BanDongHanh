import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../../../shared/widgets/gomate_logo.dart';
import '../../../social/data/mock/kho_luu_bai_viet.dart';
import '../../../social/data/mock/mock_posts.dart';
import '../../../social/presentation/widgets/post_card.dart';

/// NOTE SỬA:
/// Trang chủ:
/// - Bài mới đăng từ KhoLuuBaiViet hiện trên đầu.
/// - Ô chia sẻ lấy tên/avatar user hiện tại.
/// - Nếu tạo bài từ trang cá nhân, quay về trang chủ vẫn đúng tên người đăng.
class TrangChuPage extends StatefulWidget {
  const TrangChuPage({super.key});

  @override
  State<TrangChuPage> createState() => _TrangChuPageState();
}

class _TrangChuPageState extends State<TrangChuPage> {
  final ProfileService _profileService = ProfileService();

  MyProfile? _profile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: ListenableBuilder(
                listenable: KhoLuuBaiViet.instance,
                builder: (context, _) {
                  /// NOTE SỬA:
                  /// Bài viết mới đăng được đặt trước mockPosts.
                  final danhSachMoi = KhoLuuBaiViet.instance.danhSach;
                  final tatCa = [...danhSachMoi, ...mockPosts];

                  return ListView.builder(
                    itemCount: tatCa.length + 3,
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

                      final post = tatCa[index - 3];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == tatCa.length + 2 ? 20 : 0,
                        ),
                        child: PostCard(
                          post: post,
                          onComment: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.trangBinhLuan,
                              arguments: post.id,
                            );
                          },
                          onShare: () {
                            Navigator.pushNamed(context, AppRoutes.messages);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: MainTab.home),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.search),
            child: const Icon(
              LucideIcons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Expanded(child: GoMateLogo()),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
            child: const Icon(LucideIcons.bell, color: Colors.white, size: 23),
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
          setState(() {});
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
