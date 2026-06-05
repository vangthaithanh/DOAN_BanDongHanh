import 'dart:async';

import 'package:do_an/app/routes/app_routes.dart';
import 'package:do_an/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// NOTE SỬA:
/// Search riêng cho trang chủ.
/// Không đụng search bên tin nhắn.
/// - Tìm toàn bộ user theo display_name hoặc nickname.
/// - Kết quả hiện avatar tròn, tên hiển thị, biệt danh.
/// - Bấm user thì mở trang cá nhân user đó.
class GlobalUserSearchPage extends StatefulWidget {
  const GlobalUserSearchPage({super.key});

  @override
  State<GlobalUserSearchPage> createState() => _GlobalUserSearchPageState();
}

class _SearchUser {
  final String id;
  final String displayName;
  final String nickname;
  final String avatarUrl;

  const _SearchUser({
    required this.id,
    required this.displayName,
    required this.nickname,
    required this.avatarUrl,
  });

  factory _SearchUser.fromMap(Map<String, dynamic> map) {
    return _SearchUser(
      id: (map['id'] ?? '').toString(),
      displayName: (map['full_name'] ?? '').toString().trim(),
      nickname: (map['nickname'] ?? '').toString().trim(),
      avatarUrl: (map['avatar_url'] ?? '').toString().trim(),
    );
  }
}

class _GlobalUserSearchPageState extends State<GlobalUserSearchPage> {
  final TextEditingController searchController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  Timer? debounce;
  bool isLoading = false;
  String keyword = '';
  String? errorMessage;
  List<_SearchUser> users = [];

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged(String value) {
    setState(() {
      keyword = value.trim();
    });

    debounce?.cancel();

    debounce = Timer(const Duration(milliseconds: 350), () {
      searchUsers(value);
    });
  }

  Future<void> searchUsers(String value) async {
    final text = value.trim();

    if (text.isEmpty) {
      setState(() {
        users = [];
        isLoading = false;
        errorMessage = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final safeText = text
          .replaceAll(',', '')
          .replaceAll('%', '')
          .replaceAll("'", '');

      final data = await supabase
          .from('profiles')
          .select('id, full_name, nickname, avatar_url')
          .or('full_name.ilike.%$safeText%,nickname.ilike.%$safeText%')
          .limit(30);

      final result = (data as List)
          .map((item) => _SearchUser.fromMap(Map<String, dynamic>.from(item)))
          .where((user) => user.id.isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        users = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void clearSearch() {
    debounce?.cancel();
    searchController.clear();

    setState(() {
      keyword = '';
      users = [];
      isLoading = false;
      errorMessage = null;
    });
  }

  void openUserProfile(_SearchUser user) {
    FocusScope.of(context).unfocus();

    /// Nếu route trang cá nhân của m không phải AppRoutes.profile
    /// thì đổi dòng này thành route trang cá nhân đang dùng.
    Navigator.pushNamed(context, AppRoutes.profile, arguments: user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            topSearchBar(),
            Expanded(child: body()),
          ],
        ),
      ),
    );
  }

  Widget topSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(100),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white54, size: 21),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: onSearchChanged,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Tìm theo tên hoặc biệt danh',
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  if (keyword.isNotEmpty)
                    InkWell(
                      onTap: clearSearch,
                      borderRadius: BorderRadius.circular(100),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 19,
                        ),
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

  Widget body() {
    if (keyword.isEmpty) {
      return emptyState(
        icon: Icons.search,
        title: 'Tìm kiếm người dùng',
        message: 'Nhập tên hiển thị hoặc biệt danh để tìm user.',
      );
    }

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (errorMessage != null) {
      return emptyState(
        icon: Icons.error_outline,
        title: 'Không tìm kiếm được',
        message: errorMessage!,
      );
    }

    if (users.isEmpty) {
      return emptyState(
        icon: Icons.person_off_outlined,
        title: 'Không tìm thấy user',
        message: 'Không có user nào khớp với "$keyword".',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.border, indent: 72),
      itemBuilder: (context, index) {
        return userTile(users[index]);
      },
    );
  }

  Widget userTile(_SearchUser user) {
    final name = user.displayName.isNotEmpty ? user.displayName : user.nickname;

    final nickname = user.nickname.isNotEmpty
        ? '@${user.nickname}'
        : '@chưa có biệt danh';

    return InkWell(
      onTap: () => openUserProfile(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              backgroundImage: user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : null,
              child: user.avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30, size: 22),
          ],
        ),
      ),
    );
  }

  Widget emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white30, size: 42),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
