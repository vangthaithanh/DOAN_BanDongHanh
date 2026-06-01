import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../messages/data/mock/mock_messages.dart';
import '../../../messages/presentation/pages/trang_doan_chat.dart';
import '../../data/mock/mock_users.dart';
import '../../data/models/user_profile_model.dart';

class TrangHoSoNguoiDungPage extends StatefulWidget {
  final String userName;
  final bool isFollowing;

  const TrangHoSoNguoiDungPage({
    super.key,
    required this.userName,
    required this.isFollowing,
  });

  @override
  State<TrangHoSoNguoiDungPage> createState() =>
      _TrangHoSoNguoiDungPageState();
}

class _TrangHoSoNguoiDungPageState
    extends State<TrangHoSoNguoiDungPage> {
  late UserProfileModel profile;
  late bool _isFollowing;
  @override
  void initState() {
    super.initState();

    profile = mockUsers[widget.userName]!;

    _isFollowing = profile.isFollowing;
    _isPrivate = profile.isPrivate;
  }
  late bool _isPrivate;

  void _showFollowOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.42,

          decoration: const BoxDecoration(
            color: Color(0xFF2D2D2D),

            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),

          child: Column(
            children: [

              const SizedBox(height: 12),

              Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                nicknames[widget.userName] ??
                    widget.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Divider(
                color: Colors.white12,
                height: 1,
              ),

              ListTile(
                leading: const Icon(
                  LucideIcons.userMinus,
                  color: Colors.white,
                ),

                title: const Text(
                  'Bỏ theo dõi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),

                onTap: () {
                  Navigator.pop(context);

                  setState(() {
                    _isFollowing = false;
                  });
                },
              ),

              const Divider(
                color: Colors.white12,
                height: 1,
              ),

              ListTile(
                leading: const Icon(
                  LucideIcons.ban,
                  color: Colors.white,
                ),

                title: const Text(
                  'Chặn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),

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

  @override
  Widget build(BuildContext context) {
    final displayName =
        nicknames[widget.userName] ??
            widget.userName;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius:
                    BorderRadius.circular(18),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius:
                        BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF4AA8FF),
            ),

            const SizedBox(height: 12),

            Text(
              profile.fullName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  '${profile.followerCount} Người theo dõi',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                SizedBox(width: 24),
                Text(
                  '${profile.friendCount} Bạn bè',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tiểu sử',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_isFollowing) {
                          _showFollowOptions();
                        } else {
                          setState(() {
                            _isFollowing = true;
                          });
                        }
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isFollowing
                                    ? 'Đang theo dõi'
                                    : 'Theo dõi',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              if (_isFollowing) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.expand_more,
                                  color: Colors.white70,
                                  size: 16,
                                )
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {

                        allChatsData.putIfAbsent(
                          widget.userName,
                              () => [],
                        );

                        if (!normalMessages.any(
                              (e) => e.name == widget.userName,
                        )) {

                          normalMessages.add(
                            ChatData(
                              name: widget.userName,
                              lastMessage: '',
                              time: 'Vừa xong',
                            ),
                          );
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrangDoanChatPage(
                              name: widget.userName,
                              isWaiting: false,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Nhắn tin',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Icon(
              LucideIcons.images,
              color: Colors.white,
            ),

            const SizedBox(height: 8),

            Container(
              width: 70,
              height: 2,
              color: Colors.white,
            ),

            const Spacer(),

            if (_isPrivate && !_isFollowing)
              const Column(
                children: [
                  Icon(
                    LucideIcons.lock,
                    color: Colors.white54,
                    size: 64,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Đây là trang cá nhân riêng tư',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              )
            else
              const Column(
                children: [
                  Icon(
                    LucideIcons.camera,
                    color: Colors.white54,
                    size: 64,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có bài viết',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}