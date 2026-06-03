import 'package:flutter/material.dart';

import '../../../messages/presentation/pages/trang_doan_chat.dart';
import '../../data/mock/mock_users.dart';
import 'trang_danhsach_banbe.dart';
import 'trang_hoso_nguoidung.dart';

class TrangDanhSachNguoiTheoDoiPage
    extends StatefulWidget {

  const TrangDanhSachNguoiTheoDoiPage({
    super.key,
  });

  @override
  State<TrangDanhSachNguoiTheoDoiPage> createState() =>
      _TrangDanhSachNguoiTheoDoiPageState();
}

class _TrangDanhSachNguoiTheoDoiPageState
    extends State<TrangDanhSachNguoiTheoDoiPage> {

  late Map<String, bool> followStatus;

  @override
  void initState() {
    super.initState();

    followStatus = {};

    for (final userName in mockFollowers) {
      followStatus[userName] =
          mockUsers[userName]!.isFollowing;
    }
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

                  ...mockFollowers.map(
                        (userName) {

                      final user =
                      mockUsers[userName]!;

                      return _userTile(
                        context,
                        userName,
                        user.fullName,
                        followStatus[userName]!,
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

                  ...mockSuggestions.map(
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
      padding:
      const EdgeInsets.all(16),
      child: Row(
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
            child: Text(
              '115 Người theo dõi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const TrangDanhSachBanBePage(),
                ),
              );
            },
            child: const Text(
              '50 Bạn bè',
            ),
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

      trailing: ElevatedButton(
        onPressed: () {

          if (following) {

            setState(() {
              followStatus[userName] = false;
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

            return;
          }

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

        child: Text(
          following
              ? 'Theo dõi lại'
              : 'Nhắn tin',
        ),
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
            builder: (_) =>
                TrangHoSoNguoiDungPage(
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
          'Theo dõi',
        ),
      ),
    );
  }
}