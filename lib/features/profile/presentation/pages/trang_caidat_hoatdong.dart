import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../users/data/block_service.dart';

class TrangCaiDatHoatDongPage extends StatefulWidget {
  const TrangCaiDatHoatDongPage({super.key});

  @override
  State<TrangCaiDatHoatDongPage> createState() =>
      _TrangCaiDatHoatDongPageState();
}

class _TrangCaiDatHoatDongPageState extends State<TrangCaiDatHoatDongPage> {
  final AuthService _authService = AuthService();
  final BlockService _blockService = BlockService();

  bool _loggingOut = false;
  bool _isAdmin = false;
  int _blockedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBlockedCount();
    _loadAdminStatus();
  }

  Future<void> _loadBlockedCount() async {
    final c = await _blockService.countBlocked();
    if (mounted) setState(() => _blockedCount = c);
  }

  Future<void> _loadAdminStatus() async {
    try {
      final profile = await _authService.getCurrentProfile();

      if (!mounted) return;

      setState(() {
        _isAdmin = profile?['role'] == 'admin';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _showChangePasswordSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return _ChangePasswordSheet(authService: _authService);
      },
    );

    if (!mounted || result != true) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đổi mật khẩu'),
        backgroundColor: Color(0xFF4AA8FF),
      ),
    );
  }

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

  void _goAdminPage() {
    Navigator.pushNamed(context, AppRoutes.adminDashboard);
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
            _item(
              icon: Icons.password_rounded,
              title: 'Đổi mật khẩu',
              subtitle: 'Cập nhật mật khẩu đăng nhập',
              onTap: _loggingOut ? null : _showChangePasswordSheet,
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

              // NOTE SỬA LƯU TRỮ:
              // Nếu Kho lưu trữ trả về true sau khi khôi phục bài,
              // màn Cài đặt cũng pop true về Trang cá nhân để Trang cá nhân reload.
              onTap: _loggingOut
                  ? null
                  : () async {
                      final nav = Navigator.of(context);
                      final changed = await nav.pushNamed(AppRoutes.archive);
                      if (!mounted) return;
                      if (changed == true) nav.pop(true);
                    },
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
              trailingText: _blockedCount > 0 ? '$_blockedCount' : null,
              onTap: () async {
                await Navigator.pushNamed(context, AppRoutes.blockedUsers);
                // Cập nhật lại số đếm sau khi bỏ chặn
                if (mounted) {
                  final c = await _blockService.countBlocked();
                  if (mounted) setState(() => _blockedCount = c);
                }
              },
            ),
            _item(
              icon: Icons.location_on_outlined,
              title: 'Tin, khoảnh khắc và vị trí',
              onTap: () => _comingSoon('Tin, khoảnh khắc và vị trí'),
            ),
            _divider(),

            if (_isAdmin) ...[
              _sectionTitle('Quản trị'),
              _item(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Quản trị viên',
                subtitle: 'Quản lý tài khoản, bài viết và thống kê',
                trailingText: 'Admin',
                onTap: _loggingOut ? null : _goAdminPage,
              ),
              _divider(),
            ],

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

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.authService});

  final AuthService authService;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _changingPassword = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _changingPassword) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _changingPassword = true;
    });

    try {
      await widget.authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 120));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _changingPassword = false;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Đổi mật khẩu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _passwordField(
              controller: _oldPasswordController,
              label: 'Mật khẩu cũ',
              obscureText: !_showOldPassword,
              onToggle: () {
                setState(() {
                  _showOldPassword = !_showOldPassword;
                });
              },
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Vui lòng nhập mật khẩu cũ';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _newPasswordController,
              label: 'Mật khẩu mới',
              obscureText: !_showNewPassword,
              onToggle: () {
                setState(() {
                  _showNewPassword = !_showNewPassword;
                });
              },
              validator: (value) {
                if ((value ?? '').length < 8) {
                  return 'Mật khẩu mới tối thiểu 8 ký tự';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu mới',
              obscureText: !_showConfirmPassword,
              onToggle: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return 'Xác nhận mật khẩu mới không khớp';
                }

                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _changingPassword ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4AA8FF),
                  disabledBackgroundColor: const Color(
                    0xFF4AA8FF,
                  ).withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: _changingPassword
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Cập nhật mật khẩu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      cursorColor: const Color(0xFF4AA8FF),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white60,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFF2B2B2B),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white54,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF343434)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4AA8FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
