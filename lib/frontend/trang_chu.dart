import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PostData {
  final String name;
  final String location;
  final String nearText;
  final String caption;
  final List<String> images;
  final int likes;

  const PostData({
    required this.name,
    required this.location,
    required this.nearText,
    required this.caption,
    required this.images,
    required this.likes,
  });
}
const double contentIndent = 52;
const List<PostData> mockPosts = [
  PostData(
    name: 'Bụi',
    location: 'Vị trí chỗ này gần thị địa điểm nếu có)',
    nearText: 'Gần nhất hiện nếu có [gần để dựa trên đây đề xuất bài viết]',
    caption: 'Caption',
    images: [
      'assets/images/anh1.jpg',
      'assets/images/anh2.jpg',
      'assets/images/anh3.jpg',
      'assets/images/anh3.jpg',
      'assets/images/anh3.jpg',
      'assets/images/anh3.jpg',
      'assets/images/anh3.jpg',
      'assets/images/anh3.jpg',
    ],
    likes: 4,
  ),
  PostData(
    name: 'BongAnhHung',
    location: 'Vị trí chỗ này gần thị địa điểm nếu có)',
    nearText: 'Gần nhất hiện nếu có [gần để dựa trên đây đề xuất bài viết]',
    caption: 'Caption',
    images: [
      'assets/images/anh1.jpg',
      'assets/images/anh2.jpg',
      'assets/images/anh3.jpg',
    ],
    likes: 7,
  ),
  PostData(
    name: 'Trọng Bùi',
    location: 'Đà Lạt',
    nearText: 'Gần nhất hiện nếu có [gần để dựa trên đây đề xuất bài viết]',
    caption: 'Đi chơi cuối tuần',
    images: [
      'assets/images/anh1.jpg',
      'assets/images/anh2.jpg',
      'assets/images/anh3.jpg',
    ],
    likes: 12,
  ),
];

class TrangChuPage extends StatelessWidget {
  const TrangChuPage({super.key});

  static const Color blue = Color(0xFF4AA8FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: ListView.builder(

                itemCount: mockPosts.length + 3,
                itemBuilder: (context, index) {
                  if (index == 0) return const SizedBox(height: 10);
                  if (index == 1) return _shareBox();
                  if (index == 2) return const SizedBox(height: 12);

                  final post = mockPosts[index - 3];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == mockPosts.length + 2 ? 20 : 12,
                    ),
                    child: _postCard(post),
                  );
                },
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: const Icon(
              LucideIcons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Go',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: 'Mate',
                    style: TextStyle(
                      color: blue,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/trang_thongbao');
            },
            child: const Icon(
              LucideIcons.bell,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF242424), width: 1),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFF5AB2FF),
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
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(PostData post) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF242424), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF5AB2FF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _metaLine(
                      icon: LucideIcons.mapPinned,
                      text: post.location,
                      color: Colors.white70,
                      fontSize: 12,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    _metaLine(
                      icon: LucideIcons.tag,
                      text: post.nearText,
                      color: Colors.white54,
                      fontSize: 12,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              post.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: contentIndent, right: 16),
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: post.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _postImage(post.images[index]);
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Row(
              children: [
                const Icon(LucideIcons.heart, color: blue, size: 20),
                const SizedBox(width: 5),
                Text(
                  '${post.likes}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 18),
                const Icon(LucideIcons.messageCircle, color: Colors.white, size: 20),
                const SizedBox(width: 18),
                const Icon(LucideIcons.sendHorizontal, color: Colors.white, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaLine({
    required IconData icon,
    required String text,
    required Color color,
    required double fontSize,
    required int maxLines,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: fontSize + 2),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _postImage(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 270,
        height: 270,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF222222),
              alignment: Alignment.center,
              child: const Text(
                'Không thấy ảnh',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/trang-chu',
                      (route) => false,
                );
              },
              child: const Icon(
                LucideIcons.house,
                color: Color(0xFF3E96D8),
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
                Navigator.pushNamed(context, '/map');
              },
              child: const Icon(
                LucideIcons.mapPin,
                color: Colors.white,
                size: 24,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/trang-tinnhan');
              },
              child: const Icon(
                LucideIcons.messagesSquare,
                color: Colors.white,
                size: 24,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/trang-canhan');
              },
              child: const Icon(
                LucideIcons.userRound,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}