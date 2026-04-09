import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

ColorFilter _iconColor(bool isActive) {
  return ColorFilter.mode(
    isActive ? Colors.white : Colors.white70,
    BlendMode.srcIn,
  );
}

class ProfilePlanItem {
  final String title;
  final String timeText;
  final String actionText;
  final bool isActive;

  const ProfilePlanItem({
    required this.title,
    required this.timeText,
    required this.actionText,
    this.isActive = false,
  });
}

class ProfilePlanGroup {
  final String name;
  final String routeText;
  final List<ProfilePlanItem> items;

  const ProfilePlanGroup({
    required this.name,
    required this.routeText,
    required this.items,
  });
}

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

  int selectedTab = 0; // 0 = bài viết, 1 = plan
  int selectedPlanIndex = 0;

  final List<String> postImages = const [
    'assets/images/anh1.jpg',
    'assets/images/anh2.jpg',
    'assets/images/anh3.jpg',
  ];
  final List<ProfilePlanGroup> planGroups = const [
    ProfilePlanGroup(
      name: 'Plan 1',
      routeText: 'Đà Nẵng - Huế',
      items: [
        ProfilePlanItem(
          title: 'Bán đảo sơn trà',
          timeText: 'Th2-6 - 4, 15:30',
          actionText: 'Đánh giá',
        ),
        ProfilePlanItem(
          title: 'Cộng CF',
          timeText: 'Th2-6 - 4, 16:30',
          actionText: 'Đi lại',
        ),
        ProfilePlanItem(
          title: 'Mỳ quảng gà Bà Đình',
          timeText: 'Th2-6 - 4, 19:30',
          actionText: 'Xem điểm đến',
          isActive: true,
        ),
      ],
    ),
    ProfilePlanGroup(
      name: 'Plan 2',
      routeText: 'Huế - Đà Nẵng',
      items: [
        ProfilePlanItem(
          title: 'Đại Nội Huế',
          timeText: 'Th7-5 - 5, 08:30',
          actionText: 'Đánh giá',
        ),
        ProfilePlanItem(
          title: 'Cà phê muối',
          timeText: 'Th7-5 - 5, 10:00',
          actionText: 'Đi lại',
        ),
        ProfilePlanItem(
          title: 'Chợ Đông Ba',
          timeText: 'Th7-5 - 5, 15:30',
          actionText: 'Xem điểm đến',
          isActive: true,
        ),
      ],
    ),
    ProfilePlanGroup(
      name: 'Plan 3',
      routeText: 'Quảng Ngãi',
      items: [
        ProfilePlanItem(
          title: 'Đầm An Khê',
          timeText: 'Th7-5 - 5, 08:30',
          actionText: 'Đánh giá',
        ),
        ProfilePlanItem(
          title: 'Quán ốc sông cầu',
          timeText: 'Th7-5 - 5, 10:00',
          actionText: 'Đi lại',
        ),
        ProfilePlanItem(
          title: 'Bãi biển Mỹ Khê',
          timeText: 'Th7-5 - 5, 15:30',
          actionText: 'Xem điểm đến',
          isActive: true,
        ),
        ProfilePlanItem(
          title: 'Lủng Ồ Ba Tơ',
          timeText: 'Th4-10 - 5, 13:30',
          actionText: 'Xem điểm đến',
          isActive: true,
        ),
      ],
    ),
  ];

  ProfilePlanGroup get currentPlan => planGroups[selectedPlanIndex];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _profileHeader(),
                  ),
                  _tabButtons(),
                  if (selectedTab == 0) ...[
                    _shareBox(),
                    _postCard(),
                  ] else ...[
                    _planList(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => _showCreateSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                LucideIcons.plus,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Xuthu',
              textAlign: TextAlign.center,
              style: _textStyle(
                size: 20,
                weight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                LucideIcons.menu,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF5AB2FF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xuân Thu',
                      style: _textStyle(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '4 Người theo dõi',
                          style: _textStyle(
                            size: 12,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Text(
                          '4 Bạn bè',
                          style: _textStyle(
                            size: 12,
                            weight: FontWeight.w600,
                          ),
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
          'Tiểu sử',
          style: _textStyle(
            size: 13,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Link fb.....',
          style: _textStyle(
            size: 13,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _grayButton('Chỉnh sửa')),
            const SizedBox(width: 12),
            Expanded(child: _grayButton('Lịch trình')),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _tabButtons() {
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _postTabButton()),
          Expanded(child: _planTabButton()),
        ],
      ),
    );
  }

  Widget _postTabButton() {
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = 0;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: SvgPicture.asset(
              'assets/icons/baiviet.svg',
              fit: BoxFit.contain,
              colorFilter: _iconColor(selectedTab == 0),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            color: selectedTab == 0 ? Colors.white : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _planTabButton() {
    return PopupMenuButton<int>(
      color: const Color(0xFF3A3A3A),
      surfaceTintColor: const Color(0xFF3A3A3A),
      elevation: 8,
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onOpened: () {
        setState(() {
          selectedTab = 1;
        });
      },
      onSelected: (value) {
        setState(() {
          selectedTab = 1;
          selectedPlanIndex = value;
        });
      },
      itemBuilder: (context) {
        return List.generate(planGroups.length, (index) {
          final plan = planGroups[index];
          final isSelected = selectedPlanIndex == index;

          return PopupMenuItem<int>(
            value: index,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: _textStyle(
                          size: 12,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.routeText,
                        style: _textStyle(
                          size: 11,
                          weight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: blue,
                    size: 16,
                  ),
              ],
            ),
          );
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
                size: 24,
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: selectedTab == 1 ? Colors.white : Colors.white70,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            color: selectedTab == 1 ? Colors.white : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _shareBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF5AB2FF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xuthu',
                  style: _textStyle(
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Chia sẻ điều gì mới?',
                  style: _textStyle(
                    size: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF5AB2FF),
              ),
              const SizedBox(width: 10),
              Text(
                'Xuthu',
                style: _textStyle(
                  size: 13,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Caption',
            style: _textStyle(
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _postImage(postImages[0])),
              const SizedBox(width: 8),
              Expanded(child: _postImage(postImages[1])),
              const SizedBox(width: 8),
              Expanded(child: _postImage(postImages[2])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(LucideIcons.heart, color: blue, size: 18),
              const SizedBox(width: 4),
              Text(
                '4',
                style: _textStyle(size: 12),
              ),
              const SizedBox(width: 14),
              const Icon(
                LucideIcons.messageCircle,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 14),
              const Icon(
                LucideIcons.sendHorizontal,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _postImage(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 105,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF222222),
              alignment: Alignment.center,
              child: Text(
                'Không thấy ảnh',
                style: _textStyle(
                  size: 11,
                  color: Colors.white54,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _planList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              currentPlan.name,
              style: _textStyle(
                size: 15,
                weight: FontWeight.w700,
              ),
            ),
          ),
          ...currentPlan.items.map((item) => _planRow(item)),
        ],
      ),
    );
  }

  Widget _planRow(ProfilePlanItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  style: _textStyle(
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.timeText,
                  style: _textStyle(
                    size: 11,
                    weight: FontWeight.w500,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _planActionButton(item.actionText),
        ],
      ),
    );
  }

  Widget _planActionButton(String text) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6DB9F3),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: _textStyle(
          size: 10,
          weight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _grayButton(String text) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: softGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: _textStyle(
          size: 12,
          weight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Color(0xFF1E1E1E)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/trang-chu');
              },
              child: const Icon(
                LucideIcons.house,
                color: Colors.white,
                size: 24,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/');
              },
              child: const Icon(
                LucideIcons.aperture,
                color: Colors.white,
                size: 24,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/');
              },
              child: const Icon(
                LucideIcons.mapPin,
                color: Colors.white,
                size: 24,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/');
              },
              child: const Icon(
                LucideIcons.messagesSquare,
                color: Colors.white,
                size: 24,
              ),
            ),
            InkWell(
              onTap: () {},
              child: const Icon(
                LucideIcons.userRound,
                color: blue,
                size: 24,
              ),
            ),
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
              Text(
                'Tạo',
                style: _textStyle(
                  size: 24,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _sheetSvgItem(
                assetPath: 'assets/icons/baiviet.svg',
                text: 'Bài viết',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _sheetIconItem(
                icon: LucideIcons.aperture,
                text: 'Khoảnh khắc',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _sheetIconItem(
                icon: LucideIcons.calendarRange,
                text: 'Lịch trình',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetSvgItem({
    required String assetPath,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF4A4A4A)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: SvgPicture.asset(
                assetPath,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              text,
              style: _textStyle(
                size: 15,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetIconItem({
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
          border: Border(
            top: BorderSide(color: Color(0xFF4A4A4A)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 14),
            Text(
              text,
              style: _textStyle(
                size: 15,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}