import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';

/// NOTE SỬA:
/// Màn này là màn mở ra khi bấm nút 3 gạch ở trang cá nhân.
/// Làm giao diện giống "Cài đặt và hoạt động" cơ bản.
/// Có chức năng Đăng xuất thật.
class TrangCaiDatHoatDongPage extends StatefulWidget {
  const TrangCaiDatHoatDongPage({super.key});

  @override
  State<TrangCaiDatHoatDongPage> createState() =>
      _TrangCaiDatHoatDongPageState();
}

class _TrangCaiDatHoatDongPageState extends State<TrangCaiDatHoatDongPage> {
  final AuthService _authService = AuthService();

  bool _loggingOut = false;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Bạn có chắc muốn đăng xuất khỏi GoMate không?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      _loggingOut = true;
    });

    try {
      await _authService.signOut();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.start,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _comingSoon(String title) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title đang phát triển'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _loggingOut ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Cài đặt và hoạt động',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _sectionTitle('Tài khoản của bạn'),
            _item(
              icon: Icons.account_circle_outlined,
              title: 'Trung tâm tài khoản',
              subtitle: 'Mật khẩu, bảo mật, thông tin cá nhân',
              trailingText: 'GoMate',
              onTap: () => _comingSoon('Trung tâm tài khoản'),
            ),
            _divider(),

            _sectionTitle('Cách bạn dùng GoMate'),
            _item(
              icon: Icons.bookmark_border_rounded,
              title: 'Đã lưu',
              onTap: () => _comingSoon('Đã lưu'),
            ),
            _item(
              icon: Icons.archive_outlined,
              title: 'Kho lưu trữ',
              onTap: () => _comingSoon('Kho lưu trữ'),
            ),
            _item(
              icon: Icons.history_rounded,
              title: 'Hoạt động của bạn',
              onTap: () => _comingSoon('Hoạt động của bạn'),
            ),
            _item(
              icon: Icons.notifications_none_rounded,
              title: 'Thông báo',
              onTap: () => _comingSoon('Thông báo'),
            ),
            _item(
              icon: Icons.access_time_rounded,
              title: 'Quản lý thời gian',
              onTap: () => _comingSoon('Quản lý thời gian'),
            ),
            _divider(),

            _sectionTitle('Ai có thể xem nội dung của bạn'),
            _item(
              icon: Icons.lock_outline_rounded,
              title: 'Quyền riêng tư của tài khoản',
              trailingText: 'Công khai',
              onTap: () => _comingSoon('Quyền riêng tư'),
            ),
            _item(
              icon: Icons.star_border_rounded,
              title: 'Bạn thân',
              trailingText: '1',
              onTap: () => _comingSoon('Bạn thân'),
            ),
            _item(
              icon: Icons.block_rounded,
              title: 'Đã chặn',
              trailingText: '0',
              onTap: () => _comingSoon('Đã chặn'),
            ),
            _item(
              icon: Icons.location_on_outlined,
              title: 'Tin, khoảnh khắc và vị trí',
              onTap: () => _comingSoon('Tin, khoảnh khắc và vị trí'),
            ),
            _divider(),

            _sectionTitle('Đăng nhập'),
            _item(
              icon: Icons.logout_rounded,
              title: _loggingOut ? 'Đang đăng xuất...' : 'Đăng xuất',
              titleColor: Colors.redAccent,
              showArrow: false,
              onTap: _loggingOut ? null : _logout,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(height: 6, color: const Color(0xFF101317));
  }

  Widget _item({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    Color titleColor = Colors.white,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 25),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Text(
                trailingText,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white54,
                size: 25,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
