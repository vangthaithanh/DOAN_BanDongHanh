import 'package:flutter/material.dart';

class TrangCaNhanPage extends StatefulWidget {
  const TrangCaNhanPage({super.key});

  @override
  State<TrangCaNhanPage> createState() => _TrangCaNhanPageState();
}

class _TrangCaNhanPageState extends State<TrangCaNhanPage> {
  int selectedTab = 0; // 0 = bài viết, 1 = khoảnh khắc

  final List<String> postImages = [
    'assets/images/anh1.jpg',
    'assets/images/anh2.jpg',
    'assets/images/anh3.jpg',
  ];

  final List<String> momentImages = [
    'assets/images/khoanhkhac1.jpg',
    'assets/images/khoanhkhac2.jpg',
    'assets/images/khoanhkhac3.jpg',
    'assets/images/khoanhkhac4.jpg',
    'assets/images/khoanhkhac5.jpg',
    'assets/images/khoanhkhac6.jpg',
    'assets/images/khoanhkhac6.jpg',
    'assets/images/khoanhkhac6.jpg',
    'assets/images/khoanhkhac6.jpg',
    'assets/images/khoanhkhac6.jpg',
    'assets/images/khoanhkhac6.jpg',

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: _profileHeader(),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedTabBarDelegate(
                      child: Container(
                        color: Colors.black,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: _tabButtons(),
                      ),
                    ),
                  ),
                  ..._buildContentSlivers(),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  List<Widget> _buildContentSlivers() {
    if (selectedTab == 0) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _shareBox(),
                const SizedBox(height: 12),
                _postCard(),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  momentImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF222222),
                      alignment: Alignment.center,
                      child: const Text(
                        'Không thấy ảnh',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            childCount: momentImages.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
        ),
      ),
    ];
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => _showCreateSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          const Expanded(
            child: Text(
              'Xuthu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: () {},
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

  Widget _profileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF5AB2FF),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xuân Thu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '4 Người theo dõi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 18),
                        Text(
                          '4 Bạn bè',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
        const Text(
          'Tiểu sử',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Link fb....',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
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
      ],
    );
  }

  Widget _tabButtons() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                selectedTab = 0;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.post_add_outlined,
                  color: selectedTab == 0 ? Colors.white : Colors.white70,
                  size: 22,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  color: selectedTab == 0 ? Colors.white : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                selectedTab = 1;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  color: selectedTab == 1 ? Colors.white : Colors.white70,
                  size: 22,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  color: selectedTab == 1 ? Colors.white : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _shareBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF242424)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF5AB2FF),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xuthu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Chia sẻ điều gì mới?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF242424)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF5AB2FF),
              ),
              SizedBox(width: 10),
              Text(
                'Xuthu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Caption',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
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
          const Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.blue, size: 18),
              SizedBox(width: 4),
              Text(
                '4',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              SizedBox(width: 14),
              Icon(Icons.mode_comment_outlined, color: Colors.white, size: 18),
              SizedBox(width: 14),
              Icon(Icons.send_outlined, color: Colors.white, size: 18),
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
              child: const Text(
                'Không thấy ảnh',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _grayButton(String text) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    const blue = Color(0xFF4AA8FF);

    return Container(
      height: 62,
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
              Icons.home_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: const Icon(
              Icons.public,
              color: Colors.white,
              size: 22,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 22,
            ),
          ),
          InkWell(
            onTap: () {},
            child: const Icon(
              Icons.person_outline,
              color: blue,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF2B2B2B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tạo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _sheetItem(Icons.post_add_outlined, 'Bài viết'),
              _sheetItem(Icons.blur_circular_outlined, 'Khoảnh khắc'),
              _sheetItem(Icons.event_note_outlined, 'Lịch trình'),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetItem(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF3A3A3A)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PinnedTabBarDelegate({required this.child});

  @override
  double get minExtent => 54;

  @override
  double get maxExtent => 54;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}