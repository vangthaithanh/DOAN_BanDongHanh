import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../users/data/mock/mock_users.dart';
import '../../../users/presentation/pages/trang_hoso_nguoidung.dart';

class FollowerData {
  final String name;
  final String action;

  const FollowerData({
    required this.name,
    required this.action,
  });
}

class SuggestionData {
  final String name;
  final String distance;
  final String location;

  const SuggestionData({
    required this.name,
    required this.distance,
    required this.location,
  });
}
const List<FollowerData> mockFollowers = [
  FollowerData(name: 'Buji',action: 'đã theo dõi bạn',),
  FollowerData(name: 'BongAnhHung',action: 'đã theo dõi bạn',),
  FollowerData(name: 'Thuw', action: 'đã theo dõi bạn',),
];

const List<SuggestionData> mockSuggestions = [
  SuggestionData(name: 'thuwwwww ', distance: '1km', location: 'Đang ở đảo lý sơn'),
  SuggestionData(name: 'thuwwwww ', distance: '15km', location: 'Đang ở đảo lý sơn'),
  SuggestionData(name: 'thuwwwww ', distance: '15km', location: 'Đang ở đảo lý sơn'),
  SuggestionData(name: 'thuwwwww ', distance: '15km', location: 'Đang ở đảo lý sơn'),
];

class TrangNguoiTheoDoiPage extends StatefulWidget {
  const TrangNguoiTheoDoiPage({super.key});

  @override
  State<TrangNguoiTheoDoiPage> createState() =>
      _TrangNguoiTheoDoiPageState();
}

class _TrangNguoiTheoDoiPageState
    extends State<TrangNguoiTheoDoiPage> {

  static const Color blue = Color(0xFF4AA8FF);
  static const String fontFamily = 'Inter';

  late List<FollowerData> followers;
  late List<SuggestionData> suggestions;

  @override
  void initState() {
    super.initState();

    followers =
    List<FollowerData>.from(mockFollowers);

    suggestions =
    List<SuggestionData>.from(mockSuggestions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _topBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    _sectionTitle(
                      'Người theo dõi mới',
                    ),

                    ...followers.map(
                          (item) =>
                          _followerItem(
                            context,
                            item,
                          ),
                    ),

                    const SizedBox(height: 24),

                    _sectionTitle(
                      'Gợi ý kết bạn',
                    ),

                    ...suggestions.map(
                          (item) =>
                          _suggestionItem(
                            context,
                            item,
                          ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- CÁC COMPONENT NHỎ ---

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Khám phá mọi người',
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
  Widget _followerItem(
      BuildContext context,
      FollowerData data,
      ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TrangHoSoNguoiDungPage(
                  userName: data.name,
                  isFollowing:
                  mockUsers[data.name]!
                      .isFollowing,
                ),
          ),
        );
      },
      child: Padding(
        padding:
        const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: blue,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(
                      text: data.name,
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: data.action,
                    ),
                  ],
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                setState(() {
                  followers.remove(data);
                });

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã theo dõi ${data.name}',
                    ),
                    duration:
                    const Duration(
                      seconds: 1,
                    ),
                  ),
                );
              },
              child: _actionButton(
                'Theo dõi lại',
              ),
            ),

            const SizedBox(width: 12),

            GestureDetector(
              onTap: () {
                setState(() {
                  followers.remove(data);
                });
              },
              child: const Icon(
                LucideIcons.x,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _suggestionItem(
      BuildContext context,
      SuggestionData data,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: blue,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: data.name,
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.w700,
                          color:
                          Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: data.distance,
                        style:
                        const TextStyle(
                          color:
                          Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.location,
                  style: const TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              setState(() {
                suggestions.remove(data);
              });

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã theo dõi ${data.name}',
                  ),
                  duration:
                  const Duration(
                    seconds: 1,
                  ),
                ),
              );
            },
            child: _actionButton(
              'Theo dõi',
            ),
          ),
        ],
      ),
    );
  }
  Widget _actionButton(String text) {
    return Container(
      width: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}