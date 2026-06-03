import 'package:flutter/material.dart';

import '../../../messages/presentation/pages/trang_doan_chat.dart';
import '../../data/mock/mock_users.dart';
import 'trang_hoso_nguoidung.dart';
import 'trang_danhsach_nguoitheodoi.dart';
class TrangDanhSachBanBePage
    extends StatefulWidget {

  const TrangDanhSachBanBePage({
    super.key,
  });

  @override

  State<TrangDanhSachBanBePage> createState() =>
      _TrangDanhSachBanBePageState();
}

class _TrangDanhSachBanBePageState
    extends State<TrangDanhSachBanBePage> {
  late List<String> friends;
  late List<String> suggestions;

  @override
  void initState() {
    super.initState();

    friends = List<String>.from(mockFriends);
    suggestions = List<String>.from(mockSuggestions);
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Column(
          children: [

            _header(context),

            Expanded(
              child: ListView(
                children: [

                  ...friends.map(
                        (userName) {

                      final user =
                      mockUsers[userName]!;

                      return _userTile(
                        context,
                        userName,
                        user.fullName,
                        user.isFollowing,
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Gợi ý kết bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),

                  ...suggestions.map(
                        (userName) => _suggestionTile(
                      context,
                      userName,
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
  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),

              const Expanded(
                child: Center(
                  child: Text(
                    'Xuthu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const TrangDanhSachNguoiTheoDoiPage(),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const Text(
                        '115 Người theo dõi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 3,
                        color: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    const Text(
                      '50 Bạn bè',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userTile(
      BuildContext context,
      String userName,
      String fullName,
      bool following,
      ) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TrangHoSoNguoiDungPage(
                  userName: userName,
                  isFollowing: following,
                ),
          ),
        );
      },

      leading: const CircleAvatar(),

      title: Text(
        userName,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),

      subtitle: Text(
        fullName,
        style: const TextStyle(
          color: Colors.white70,
        ),
      ),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrangDoanChatPage(
                    name: userName,
                    isWaiting: false,
                  ),
                ),
              );
            },
            child: const Text('Nhắn tin'),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.close,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
  Widget _suggestionTile(
      BuildContext context,
      String userName,
      ) {
    final user = mockUsers[userName]!;

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrangHoSoNguoiDungPage(
              userName: userName,
              isFollowing: user.isFollowing,
            ),
          ),
        );
      },

      leading: const CircleAvatar(),

      title: Text(
        userName,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),

      subtitle: const Text(
        'Đang ở đảo Lý Sơn',
        style: TextStyle(
          color: Colors.white70,
        ),
      ),

      trailing: ElevatedButton(
        onPressed: () {

          setState(() {
            suggestions.remove(userName);
            friends.add(userName);
          });

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                'Đã theo dõi $userName',
              ),
              duration:
              const Duration(seconds: 1),
            ),
          );
        },

        child: const Text(
          'Theo dõi lại',
        ),
      ),
    );
  }
}