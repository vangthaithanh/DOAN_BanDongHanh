import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../../social/presentation/widgets/post_card.dart';

/// NOTE SỬA:
/// Trang cá nhân đã bỏ dữ liệu fix cứng.
/// Dữ liệu lấy từ Supabase qua ProfileService:
/// - profiles: avatar, nickname, full_name, bio, facebook_url
/// - follows: follower count
/// - friends: friend count
/// - posts: post count
/// - itineraries + itinerary_items: plan/lịch trình
///
/// NOTE RESPONSIVE:
/// - Không fix cứng theo Pixel Emulator.
/// - Dùng MediaQuery/LayoutBuilder để tự co theo màn hình.
class TrangCaNhanPage extends StatefulWidget {
  const TrangCaNhanPage({super.key});

  @override
  State<TrangCaNhanPage> createState() => _TrangCaNhanPageState();
}

class _TrangCaNhanPageState extends State<TrangCaNhanPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const Color divider = Color(0xFF242424);
  static const Color softGrey = Color(0xFF2D2D2D);
  static const Color textGrey = Color(0xFFA9A9A9);

  final ProfileService _service = ProfileService();

  late Future<ProfilePageData> _future;

  int selectedTab = 0;
  int selectedPlanIndex = 0;
  bool isPlanPickerOpen = false;

  @override
  void initState() {
    super.initState();

    _future = _service.loadMine();
  }

  void _reloadProfile() {
    setState(() {
      _future = _service.loadMine();
    });
  }

  TextStyle _textStyle({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  bool _isSmallPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 360;
  }

  double _horizontalPadding(BuildContext context) {
    return _isSmallPhone(context) ? 12.0 : 16.0;
  }

  double _planMenuWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return width < 360 ? 132 : 150;
  }

  ImageProvider? _avatarProvider(MyProfile profile) {
    if (profile.avatarUrl.trim().isEmpty) {
      return null;
    }

    return NetworkImage(profile.avatarUrl);
  }

  Widget _avatar({required MyProfile profile, required double radius}) {
    final provider = _avatarProvider(profile);

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF5AB2FF),
      backgroundImage: provider,
      child: provider == null
          ? Icon(Icons.person, color: Colors.white, size: radius)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const AppBottomNav(activeTab: MainTab.profile),
      body: SafeArea(
        child: FutureBuilder<ProfilePageData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _topBar(context, null),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  _topBar(context, null),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              snapshot.error.toString().replaceFirst(
                                'Exception: ',
                                '',
                              ),
                              textAlign: TextAlign.center,
                              style: _textStyle(
                                size: 15,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _reloadProfile,
                              child: const Text('Tải lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;

            return Column(
              children: [
                _topBar(context, data),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          _horizontalPadding(context),
                          8,
                          _horizontalPadding(context),
                          0,
                        ),
                        child: _profileHeader(context, data),
                      ),
                      _tabButtons(context),
                      if (selectedTab == 0) ...[
                        _shareBox(context, data),
                        if (data.posts.isEmpty)
                          _emptyPostBox(context, data)
                        else
                          ...data.posts.map(
                            (post) => PostCard(
                              post: post,
                              onComment: () => Navigator.pushNamed(
                                context,
                                AppRoutes.trangBinhLuan,
                                arguments: post.id,
                              ),
                              onShare: () => Navigator.pushNamed(
                                context,
                                AppRoutes.messages,
                              ),
                              onPostModified: _reloadProfile,
                            ),
                          ),
                      ] else ...[
                        _planSection(context, data),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, ProfilePageData? data) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        12,
        _horizontalPadding(context),
        8,
      ),
      child: Row(
        children: [
          // NOTE SỬA:
          // Nút bên trái là dấu + để tạo bài viết/khoảnh khắc/lịch trình.
          // Trước đó bạn để menu ở đây nên bị nhầm.
          InkWell(
            onTap: () => _showCreateSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.add, color: Colors.white, size: 26),
            ),
          ),

          Expanded(
            child: Text(
              data?.profile.displayName ?? 'Hồ sơ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: _textStyle(size: 20, weight: FontWeight.w700),
            ),
          ),

          // NOTE SỬA:
          // Nút bên phải mới là nút 3 gạch mở Cài đặt và hoạt động.
          // Trước đó onTap để rỗng nên bấm không có gì xảy ra.
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
            borderRadius: BorderRadius.circular(20),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.menu, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context, ProfilePageData data) {
    final isSmallPhone = _isSmallPhone(context);
    final avatarRadius = isSmallPhone ? 24.0 : 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(profile: data.profile, radius: avatarRadius),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NOTE SỬA:
                    /// Tên không fix cứng nữa, lấy từ Supabase.
                    Text(
                      data.profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(size: 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    /// NOTE SỬA:
                    /// Follower/Friend/Post lấy từ Supabase.
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        Text(
                          '${data.followerCount} Người theo dõi',
                          style: _textStyle(size: 12, weight: FontWeight.w600),
                        ),
                        Text(
                          '${data.friendCount} Bạn bè',
                          style: _textStyle(size: 12, weight: FontWeight.w600),
                        ),
                        Text(
                          '${data.postCount} Bài viết',
                          style: _textStyle(size: 12, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        /// NOTE SỬA:
        /// Tiểu sử lấy từ profiles.bio.
        Text(
          data.profile.bio.isNotEmpty ? data.profile.bio : 'Chưa có tiểu sử',
          style: _textStyle(size: 13, weight: FontWeight.w500),
        ),

        /// NOTE SỬA:
        /// Link Facebook lấy từ profiles.facebook_url.
        if (data.profile.facebookUrl.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            data.profile.facebookUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(size: 13, weight: FontWeight.w600, color: blue),
          ),
        ],

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _grayButton(
                'Chỉnh sửa',
                onTap: () async {
                  /// NOTE SỬA:
                  /// Mở màn chỉnh sửa thật, truyền profile hiện tại qua.
                  final updated = await Navigator.pushNamed(
                    context,
                    AppRoutes.editProfile,
                    arguments: data.profile,
                  );

                  if (updated == true) {
                    _reloadProfile();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _grayButton(
                'Lịch trình',
                onTap: () {
                  setState(() {
                    selectedTab = 1;
                    isPlanPickerOpen = false;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _tabButtons(BuildContext context) {
    return Container(
      height: 56,
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        8,
        _horizontalPadding(context),
        0,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              active: selectedTab == 0,
              icon: Icons.grid_on_rounded,
              onTap: () {
                setState(() {
                  selectedTab = 0;
                  isPlanPickerOpen = false;
                });
              },
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  if (selectedTab == 0) {
                    selectedTab = 1;
                    isPlanPickerOpen = false;
                  } else {
                    isPlanPickerOpen = !isPlanPickerOpen;
                  }
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        color: selectedTab == 1 ? Colors.white : Colors.white70,
                        size: 30,
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: selectedTab == 1 ? Colors.white : Colors.white70,
                        size: 30,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: _planMenuWidth(context),
                    child: Container(
                      height: 2,
                      color: selectedTab == 1
                          ? Colors.white
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required bool active,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? Colors.white : Colors.white70, size: 28),
          const SizedBox(height: 8),
          Container(
            height: 2,
            color: active ? Colors.white : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _shareBox(BuildContext context, ProfilePageData data) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.pushNamed(context, AppRoutes.createPost);
        if (result == true && mounted) _reloadProfile();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _horizontalPadding(context),
          vertical: 14,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: divider, width: 1)),
        ),
        child: Row(
          children: [
            _avatar(profile: data.profile, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chia sẻ điều gì mới?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(size: 14, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPostBox(BuildContext context, ProfilePageData data) {
    final imageSize = (MediaQuery.sizeOf(context).width * 0.68)
        .clamp(210.0, 290.0)
        .toDouble();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        24,
        _horizontalPadding(context),
        24,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: divider, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            width: imageSize,
            height: imageSize * 0.75,
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2D2D2D)),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: Colors.white38,
              size: 50,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Chưa có bài viết',
            style: _textStyle(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Bấm dấu + hoặc ô chia sẻ để tạo bài viết mới.',
            textAlign: TextAlign.center,
            style: _textStyle(size: 13, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _planSection(BuildContext context, ProfilePageData data) {
    return Stack(
      children: [
        _planList(context, data),
        if (isPlanPickerOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isPlanPickerOpen = false;
                });
              },
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(color: Colors.black.withOpacity(0.28)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 18,
            child: _planPickerOverlay(context, data),
          ),
        ],
      ],
    );
  }

  ProfilePlanGroupData? _currentPlan(ProfilePageData data) {
    if (data.plans.isEmpty) {
      return null;
    }

    final safeIndex = selectedPlanIndex.clamp(0, data.plans.length - 1).toInt();

    return data.plans[safeIndex];
  }

  Widget _planPickerOverlay(BuildContext context, ProfilePageData data) {
    if (data.plans.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: _planMenuWidth(context),
        color: const Color(0xFF3A3A3A),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < data.plans.length; i++) ...[
              InkWell(
                onTap: () {
                  setState(() {
                    selectedPlanIndex = i;
                    isPlanPickerOpen = false;
                    selectedTab = 1;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.plans[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _textStyle(
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              data.plans[i].routeText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _textStyle(
                                size: 13,
                                weight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedPlanIndex == i)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check, color: blue, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              if (i != data.plans.length - 1)
                Container(
                  width: double.infinity,
                  height: 6,
                  color: Colors.white.withOpacity(0.08),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _planList(BuildContext context, ProfilePageData data) {
    final plan = _currentPlan(data);

    if (plan == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          24,
          _horizontalPadding(context),
          24,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: divider, width: 1)),
        ),
        child: Text(
          'Chưa có lịch trình',
          style: _textStyle(
            size: 18,
            weight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              0,
              _horizontalPadding(context),
              8,
            ),
            child: Text(
              plan.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(size: 24, weight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              0,
              _horizontalPadding(context),
              8,
            ),
            child: Text(
              plan.routeText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textStyle(size: 14, color: Colors.white70),
            ),
          ),
          if (plan.items.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding(context),
                8,
                _horizontalPadding(context),
                18,
              ),
              child: Text(
                'Lịch trình này chưa có điểm đến',
                style: _textStyle(size: 15, color: Colors.white70),
              ),
            )
          else
            ...plan.items.map((item) => _planRow(context, item)),
        ],
      ),
    );
  }

  Widget _planRow(BuildContext context, ProfilePlanItemData item) {
    final isSmallPhone = _isSmallPhone(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding(context),
        8,
        _horizontalPadding(context),
        8,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.isActive ? blue : Colors.white38,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: isSmallPhone ? 17 : 20,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.timeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    size: isSmallPhone ? 13 : 15,
                    weight: FontWeight.w500,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _planActionButton(context, item.actionText),
        ],
      ),
    );
  }

  Widget _planActionButton(BuildContext context, String text) {
    final isSmallPhone = _isSmallPhone(context);

    return SizedBox(
      width: isSmallPhone ? 92 : 110,
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF6DB9F3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: _textStyle(
              size: isSmallPhone ? 12 : 14,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _grayButton(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: softGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _textStyle(
            size: 16,
            weight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF2F2C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tạo', style: _textStyle(size: 24, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              _sheetItem(
                icon: Icons.article_outlined,
                text: 'Bài viết',
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.pushNamed(
                    context,
                    AppRoutes.createPost,
                  );
                  if (result == true && mounted) _reloadProfile();
                },
              ),
              _sheetItem(
                icon: Icons.camera_alt_outlined,
                text: 'Khoảnh khắc',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.momentCamera);
                },
              ),
              _sheetItem(
                icon: Icons.calendar_month_outlined,
                text: 'Lịch trình',
                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    selectedTab = 1;
                    isPlanPickerOpen = false;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF4A4A4A))),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 14),
            Text(text, style: _textStyle(size: 15, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
