import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';

/// NOTE SỬA:
/// Màn nhập mật khẩu email.
///
/// SỬA CHÍNH:
/// 1. Sau khi đăng nhập thành công KHÔNG vào thẳng trang chủ.
///    Chuyển sang AppRoutes.loading để ManHinhChoPage kiểm tra:
///    - chưa avatar -> thêm ảnh đại diện
///    - chưa khảo sát -> màn câu hỏi
///    - đủ rồi -> trang chủ
///
/// 2. Form responsive:
///    - Dùng LayoutBuilder.
///    - Dùng SingleChildScrollView.
///    - Không dùng Spacer cứng.
///    - Khi bàn phím mở vẫn cuộn được.
class MatKhauEmailPage extends StatefulWidget {
  const MatKhauEmailPage({super.key});

  @override
  State<MatKhauEmailPage> createState() => _MatKhauEmailPageState();
}

class _MatKhauEmailPageState extends State<MatKhauEmailPage> {
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool isLoading = false;
  bool obscurePassword = true;

  bool get isValidPassword {
    return passwordController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin(String email) async {
    final password = passwordController.text.trim();

    if (email.trim().isEmpty) {
      _showMessage('Không tìm thấy email. Vui lòng quay lại nhập email.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Vui lòng nhập mật khẩu');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      await authService.signInWithEmail(email: email, password: password);

      if (!mounted) return;

      /// NOTE SỬA QUAN TRỌNG:
      /// Không đi thẳng vào /trang-chu.
      /// Đi qua màn loading để kiểm tra avatar/câu hỏi.
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loading,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Email hoặc mật khẩu không đúng');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final email = args?['email'] as String? ?? '';

    const blue = Color(0xFF4AA8FF);
    const field = Color(0xFF2E2E31);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isSmallPhone = width < 360;

            final horizontalPadding = isSmallPhone ? 20.0 : 24.0;
            final topGap = isSmallPhone ? 38.0 : 56.0;
            final titleSize = isSmallPhone ? 25.0 : 28.0;
            final fieldVerticalPadding = isSmallPhone ? 14.0 : 16.0;
            final buttonHeight = isSmallPhone ? 50.0 : 54.0;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _backButton(context),
                        SizedBox(height: topGap),

                        Text(
                          'Nhập mật khẩu của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (email.isNotEmpty)
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                        const SizedBox(height: 18),

                        TextField(
                          controller: passwordController,
                          onChanged: (_) => setState(() {}),
                          obscureText: obscurePassword,
                          enabled: !isLoading,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: blue,
                          decoration: InputDecoration(
                            hintText: 'Mật khẩu',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: field,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: fieldVerticalPadding,
                            ),
                            suffixIcon: IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white54,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        InkWell(
                          onTap: isLoading
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.quenMatKhauEmail,
                                    arguments: {'email': email},
                                  );
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Quên mật khẩu >',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isSmallPhone ? 120 : 170),

                        _primaryButton(
                          label: isLoading ? 'Đang đăng nhập...' : 'Tiếp tục',
                          color: isValidPassword && !isLoading
                              ? blue
                              : Colors.grey,
                          height: buttonHeight,
                          onTap: isValidPassword && !isLoading
                              ? () => handleLogin(email)
                              : null,
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: isLoading ? null : () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFF2E2E31),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required Color color,
    required double height,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
