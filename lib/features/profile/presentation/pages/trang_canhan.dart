import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../../itinerary/data/services/lich_trinh_nhom_service.dart';
import '../../../itinerary/data/services/lich_trinh_service.dart';
import '../../../social/presentation/widgets/post_card.dart';
import '../../../users/data/block_service.dart';

class TrangCaNhanPage extends StatefulWidget {
  final String? userId;

  const TrangCaNhanPage({super.key, this.userId});

  @override
  State<TrangCaNhanPage> createState() => _TrangCaNhanPageState();
}

class _TrangCaNhanPageState extends State<TrangCaNhanPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const Color divider = Color(0xFF242424);
  static const Color softGrey = Color(0xFF2D2D2D);

  final ProfileService _service = ProfileService();
  final LichTrinhService _lichTrinhService = LichTrinhService();
  final LichTrinhNhomService _lichTrinhNhomService = LichTrinhNhomService();

  late Future<ProfilePageData> _future;
  bool _isActionLoading = false;

  int selectedTab = 0;
  int selectedPlanIndex = 0;
  bool isPlanPickerOpen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _kiemTraGpsLichTrinhDangGhim();
  }

  void _loadData() {
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _future = _service.loadProfile(widget.userId!);
    } else {
      _future = _service.loadMine();
    }
  }

  void _reloadProfile() {
    setState(() {
      _loadData();
    });
  }

  Future<void> _kiemTraGpsLichTrinhDangGhim() async {
    try {
      await _lichTrinhService.kiemTraLichTrinhDangGhimBangGps();
      await _lichTrinhNhomService.kiemTraLichTrinhNhomDangGhim();

      if (!mounted) return;

      _reloadProfile();
    } catch (_) {
      // Không chặn trang cá nhân nếu user chưa bật GPS/quyền vị trí.
    }
  }

  Future<void> _togglePinPlan(ProfilePlanGroupData plan) async {
    if (plan.isGroup) {
      final tripId = int.tryParse(plan.id);

      if (tripId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xác định được lịch trình nhóm.')),
        );
        return;
      }

      try {
        await _lichTrinhNhomService.doiTrangThaiGhimNhom(
          tripId: tripId,
          pinned: !plan.pinned,
        );

        if (!mounted) return;

        _reloadProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              plan.pinned
                  ? 'Đã bỏ ghim lịch trình nhóm.'
                  : 'Đã ghim lịch trình nhóm. GoMate sẽ nhắc giờ cho lịch trình này.',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }

      return;
    }

    final planId = int.tryParse(plan.id);

    if (planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được lịch trình.')),
      );
      return;
    }

    try {
      await _lichTrinhService.doiTrangThaiGhim(
        itineraryId: planId,
        pinned: !plan.pinned,
      );

      if (!mounted) return;

      _reloadProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            plan.pinned
                ? 'Đã bỏ ghim lịch trình.'
                : 'Đã ghim lịch trình. GoMate sẽ kiểm tra GPS cho lịch trình này.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openPlanDetail(ProfilePlanGroupData plan) async {
    if (plan.isGroup) {
      final tripId = int.tryParse(plan.id);
      if (tripId == null) return;

      await Navigator.pushNamed(
        context,
        AppRoutes.groupTripDetail,
        arguments: {'tripId': tripId},
      );

      if (!mounted) return;

      _reloadProfile();

      return;
    }

    final itineraryId = int.tryParse(plan.id);
    if (itineraryId == null) return;

    await Navigator.pushNamed(
      context,
      AppRoutes.tripCreate,
      arguments: {'itineraryId': itineraryId},
    );

    if (!mounted) return;

    _reloadProfile();
  }

  Future<void> _handlePlanItemAction(ProfilePlanItemData item) async {
    if (item.actionText == 'Đánh giá') {
      final changed = await Navigator.pushNamed(
        context,
        AppRoutes.placeReview,
        arguments: item.placeId,
      );

      if (!mounted) return;

      if (changed == true) {
        _reloadProfile();
      }

      return;
    }

    if (item.actionText == 'Đặt lại') {
      final changed = await Navigator.pushNamed(
        context,
        AppRoutes.tripCreate,
        arguments: {'initialPlaceId': item.placeId},
      );

      if (!mounted) return;

      if (changed == true) {
        _reloadProfile();
      }

      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.placeDetail,
      arguments: item.placeId,
    );
  }

  Future<void> _handleFollow(String targetId) async {
    if (_isActionLoading) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      await _service.toggleFollow(targetId);
      _reloadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
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

  /// NOTE SỬA:
  /// Mở danh sách người theo dõi hoặc bạn bè của profile đang xem.
  /// type:
  /// - followers: người theo dõi
  /// - friends: bạn bè follow 2 chiều
  void _openProfileConnections({
    required String targetUserId,
    required String type,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.profileConnections,
      arguments: {'targetUserId': targetUserId, 'type': type},
    );
  }

  /// NOTE SỬA:
  /// Text thống kê có thể bấm được.
  /// Dùng cho Người theo dõi và Bạn bè.
  Widget _profileStatText({required String text, VoidCallback? onTap}) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: _textStyle(size: 12, weight: FontWeight.w600)),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: widget.userId == null
          ? const AppBottomNav(activeTab: MainTab.profile)
          : null,
      appBar: widget.userId != null
          ? AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Hồ sơ',
                style: _textStyle(size: 18, weight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: FutureBuilder<ProfilePageData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  if (widget.userId == null) _topBar(context, null),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  if (widget.userId == null) _topBar(context, null),
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

            // NOTE SỬA LƯU TRỮ:
            // Phòng trường hợp service profile vẫn trả về bài archived,
            // UI sẽ tự ẩn bài archived/deleted khỏi trang cá nhân.
            final postsHienThi = data.posts
                .where(
                  (post) =>
                      post.status != 'archived' &&
                      post.status != 'deleted' &&
                      !post.isArchived,
                )
                .toList();

            return Column(
              children: [
                if (widget.userId == null) _topBar(context, data),
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
                        if (data.isMe) _shareBox(context, data),
                        if (postsHienThi.isEmpty)
                          _emptyPostBox(context, data)
                        else
                          ...postsHienThi.map(
                            (post) => PostCard(
                              post: post,
                              onComment: () async {
                                final changed = await Navigator.pushNamed(
                                  context,
                                  AppRoutes.trangBinhLuan,
                                  arguments: post.id,
                                );

                                if (mounted && changed == true) {
                                  _reloadProfile();
                                }
                              },
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
          InkWell(
            // NOTE SỬA LƯU TRỮ:
            // Khi từ Cài đặt -> Kho lưu trữ khôi phục bài xong,
            // route sẽ trả về true để trang cá nhân load lại ngay.
            onTap: () async {
              final changed = await Navigator.pushNamed(
                context,
                AppRoutes.settings,
              );

              if (!mounted) return;

              if (changed == true) {
                _reloadProfile();
              }
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
                    Text(
                      data.profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle(size: 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    /// NOTE SỬA:
                    /// Người theo dõi và Bạn bè bấm được.
                    /// Bài viết giữ nguyên chỉ hiển thị số lượng.
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _profileStatText(
                          text: '${data.followerCount} Người theo dõi',
                          onTap: () {
                            if (!data.isMe && !data.isFollowing) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Hãy theo dõi để xem danh sách này')),
                              );
                              return;
                            }
                            _openProfileConnections(
                              targetUserId: data.profile.id,
                              type: 'followers',
                            );
                          },
                        ),
                        _profileStatText(
                          text: '${data.friendCount} Bạn bè',
                          onTap: () {
                            if (!data.isMe && !data.isFollowing) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Hãy theo dõi để xem danh sách này')),
                              );
                              return;
                            }
                            _openProfileConnections(
                              targetUserId: data.profile.id,
                              type: 'friends',
                            );
                          },
                        ),
                        _profileStatText(
                          text:
                          '${data.posts.where((post) => post.status != 'archived' && post.status != 'deleted' && !post.isArchived).length} Bài viết',
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
        Text(
          data.profile.bio.isNotEmpty ? data.profile.bio : 'Chưa có tiểu sử',
          style: _textStyle(size: 13, weight: FontWeight.w500),
        ),
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
        if (data.isMe)
          Row(
            children: [
              Expanded(
                child: _grayButton(
                  'Chỉnh sửa',
                  onTap: () async {
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
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRoutes.tripList);

                    if (!mounted) return;

                    setState(() {
                      selectedTab = 1;
                      isPlanPickerOpen = false;
                    });

                    _reloadProfile();
                  },
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (data.isFollowing) {
                      _showUnfollowSheet(
                        data.profile.id,
                        data.profile.displayName,
                      );
                      _showUnfollowSheet(
                        data.profile.id,
                        data.profile.displayName,
                      );
                    } else {
                      _handleFollow(data.profile.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: data.isFollowing ? softGrey : blue,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isActionLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          data.isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                          style: _textStyle(
                            size: 15,
                            weight: FontWeight.w700,
                            color: data.isFollowing
                                ? Colors.white70
                                : Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _grayButton(
                  'Nhắn tin',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatDetail,
                      arguments: {
                        'name': data.profile.displayName,
                        'otherProfileId': data.profile.id,
                        'avatarUrl': data.profile.avatarUrl,
                        'isWaiting': false,
                      },
                    );
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
                  child: Container(color: Colors.black.withValues(alpha: 0.28)),
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.48,
        ),
        color: const Color(0xFF3A3A3A),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                              Row(
                                children: [
                                  if (data.plans[i].isGroup) ...[
                                    _planTypeBadge('Nhóm'),
                                    const SizedBox(width: 6),
                                  ],
                                  if (data.plans[i].pinned)
                                    _planTypeBadge('Đã ghim'),
                                ],
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
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_PlanDayGroup> _groupPlanItemsByDay(List<ProfilePlanItemData> items) {
    final sortedItems = List<ProfilePlanItemData>.from(items)
      ..sort((a, b) {
        final aTime = a.plannedTime;
        final bTime = b.plannedTime;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return aTime.compareTo(bTime);
      });

    final groups = <String, List<ProfilePlanItemData>>{};
    final dates = <String, DateTime?>{};

    for (final item in sortedItems) {
      final time = item.plannedTime;

      final key = time == null
          ? 'unknown'
          : '${time.year}-${time.month}-${time.day}';

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(item);

      dates[key] = time == null
          ? null
          : DateTime(time.year, time.month, time.day);
    }

    return groups.entries.map((entry) {
      return _PlanDayGroup(date: dates[entry.key], items: entry.value);
    }).toList()..sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });
  }

  String _thuDayDu(DateTime? date) {
    if (date == null) return 'Chưa rõ ngày';

    switch (date.weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      default:
        return 'Chủ nhật';
    }
  }

  String _ngayThangText(DateTime? date) {
    if (date == null) return '';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _gioItemText(ProfilePlanItemData item) {
    final time = item.plannedTime;

    if (time == null) return item.hourText;

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Widget _planList(BuildContext context, ProfilePageData data) {
    final hasPinnedPlan = data.plans.any((plan) => plan.pinned);

    if (!hasPinnedPlan && data.plans.length > 1) {
      return Column(
        children: [
          for (final plan in data.plans) _planBlock(context, data, plan),
        ],
      );
    }

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
        child: Column(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white38,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              'Chưa có lịch trình',
              style: _textStyle(
                size: 17,
                weight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
            if (data.isMe) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final changed = await Navigator.pushNamed(
                    context,
                    AppRoutes.tripCreate,
                  );

                  if (!mounted) return;

                  if (changed == true) {
                    _reloadProfile();
                  }
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Tạo lịch trình',
                    style: _textStyle(size: 13, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return _planBlock(context, data, plan);
  }

  Widget _planBlock(
    BuildContext context,
    ProfilePageData data,
    ProfilePlanGroupData plan,
  ) {
    final dayGroups = _groupPlanItemsByDay(plan.items);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding(context),
              2,
              _horizontalPadding(context),
              10,
            ),
            child: Row(
              children: [
                Icon(
                  plan.pinned ? Icons.push_pin : Icons.event_note_outlined,
                  color: plan.pinned ? Colors.white : Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: InkWell(
                    onTap: () => _openPlanDetail(plan),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            plan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _textStyle(
                              size: 18,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (plan.isGroup) ...[
                          const SizedBox(width: 8),
                          _planTypeBadge('Nhóm'),
                        ],
                      ],
                    ),
                  ),
                ),
                if (data.isMe) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _togglePinPlan(plan),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 76),
                      height: 27,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: softGrey,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        plan.pinned ? 'Bỏ ghim' : 'Ghim',
                        style: _textStyle(
                          size: 11,
                          weight: FontWeight.w800,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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
                plan.isGroup
                    ? 'Lịch trình nhóm này chưa có điểm dừng'
                    : 'Lịch trình này chưa có điểm đến',
                style: _textStyle(size: 15, color: Colors.white70),
              ),
            )
          else
            ...dayGroups.map((group) => _planDaySection(context, group)),
        ],
      ),
    );
  }

  Widget _planDaySection(BuildContext context, _PlanDayGroup group) {
    final items = group.items;

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        left: _horizontalPadding(context),
        right: _horizontalPadding(context),
        bottom: 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF050505),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF232323)),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _thuDayDu(group.date),
                    style: _textStyle(size: 17, weight: FontWeight.w900),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _ngayThangText(group.date),
                    style: _textStyle(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Colors.white54,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${items.length} điểm',
                    style: _textStyle(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < items.length; i++)
              _planRow(context, items[i], isLastInDay: i == items.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _planPlaceImage(String? imageUrl) {
    final url = imageUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        height: 52,
        color: const Color(0xFF2B2B2B),
        child: url.isEmpty
            ? const Icon(Icons.image_outlined, color: Colors.white38, size: 22)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_outlined,
                    color: Colors.white38,
                    size: 22,
                  );
                },
              ),
      ),
    );
  }

  Widget _planRow(
    BuildContext context,
    ProfilePlanItemData item, {
    bool isLastInDay = false,
  }) {
    final isSmallPhone = _isSmallPhone(context);

    return InkWell(
      onTap: () {
        if (item.placeId > 0) {
          Navigator.pushNamed(
            context,
            AppRoutes.placeDetail,
            arguments: item.placeId,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          border: isLastInDay
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFF242424), width: 1),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: isSmallPhone ? 38 : 44,
              child: Text(
                _gioItemText(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(
                  size: isSmallPhone ? 10.5 : 11.5,
                  weight: FontWeight.w800,
                  color: Colors.white60,
                ),
              ),
            ),

            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.isActive ? blue : Colors.white54,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 10),

            _planPlaceImage(item.imageUrl),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      size: isSmallPhone ? 13.5 : 14.5,
                      weight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.province.trim().isEmpty ? 'Tỉnh thành' : item.province,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      size: isSmallPhone ? 10.5 : 11.5,
                      weight: FontWeight.w700,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            if (item.canShowAction && item.actionText.trim().isNotEmpty)
              _planActionButton(
                context,
                item.actionText,
                onTap: () => _handlePlanItemAction(item),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _planActionButton(
    BuildContext context,
    String text, {
    VoidCallback? onTap,
  }) {
    final isSmallPhone = _isSmallPhone(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: BoxConstraints(
          minWidth: isSmallPhone ? 62 : 74,
          maxWidth: isSmallPhone ? 76 : 88,
        ),
        height: 25,
        padding: const EdgeInsets.symmetric(horizontal: 7),
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
              size: isSmallPhone ? 9 : 10,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _planTypeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF183B59),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: _textStyle(size: 10, weight: FontWeight.w800, color: blue),
      ),
    );
  }

  Widget _grayButton(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 46,
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
            size: 15,
            weight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  void _showUnfollowSheet(String targetId, String displayName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                displayName,
                style: _textStyle(size: 16, weight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _sheetAction(
                icon: Icons.person_remove_outlined,
                label: 'Hủy theo dõi',
                color: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  _handleFollow(targetId);
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              _sheetAction(
                icon: Icons.block,
                label: 'Chặn tài khoản',
                color: Colors.redAccent,
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1C1C1E),
                      title: const Text(
                        'Chặn tài khoản',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'Chặn $displayName? Họ sẽ không thể xem hồ sơ và bài viết của bạn.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Chặn',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    await BlockService().blockUser(targetId);
                    // Cũng hủy theo dõi nếu đang follow
                    await _service.toggleFollow(targetId).catchError((_) {});
                    _reloadProfile();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã chặn tài khoản'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: _textStyle(size: 15, color: color)),
          ],
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
                onTap: () async {
                  Navigator.pop(context);

                  final changed = await Navigator.pushNamed(
                    context,
                    AppRoutes.tripCreate,
                  );

                  if (!mounted) return;

                  setState(() {
                    selectedTab = 1;
                    isPlanPickerOpen = false;
                  });

                  if (changed == true) {
                    _reloadProfile();
                  }
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

class _PlanDayGroup {
  final DateTime? date;
  final List<ProfilePlanItemData> items;

  const _PlanDayGroup({required this.date, required this.items});
}
