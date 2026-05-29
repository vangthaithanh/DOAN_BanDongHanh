import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../../../shared/widgets/gomate_logo.dart';
import '../../../social/data/mock/kho_luu_bai_viet.dart';
import '../../../social/data/mock/mock_posts.dart';
import '../../../social/presentation/widgets/post_card.dart';

class TrangChuPage extends StatelessWidget {
  const TrangChuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              // ListenableBuilder tự rebuild khi có bài viết mới
              child: ListenableBuilder(
                listenable: KhoLuuBaiViet.instance,
                builder: (context, _) {
                  final danhSachMoi =
                      KhoLuuBaiViet.instance.danhSach;
                  final tatCa = [
                    ...danhSachMoi,
                    ...mockPosts,
                  ];

                  return ListView.builder(
                    itemCount: tatCa.length + 3,
                    itemBuilder: (context, index) {
                      if (index == 0) return const SizedBox(height: 10);
                      if (index == 1) return _shareBox(context);
                      if (index == 2) return const SizedBox(height: 12);

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
                            Navigator.pushNamed(
                              context,
                              AppRoutes.messages,
                            );
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
            child: const Icon(LucideIcons.search, color: Colors.white, size: 24),
          ),
          const Expanded(child: GoMateLogo()),
          InkWell(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            child: const Icon(LucideIcons.bell, color: Colors.white, size: 23),
          ),
        ],
      ),
    );
  }

  Widget _shareBox(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.createPost),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xuthu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Chia sẻ điều gì mới?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
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