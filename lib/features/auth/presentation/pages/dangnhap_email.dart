import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';

class DangNhapEmailPage extends StatefulWidget {
  const DangNhapEmailPage({super.key});

  @override
  State<DangNhapEmailPage> createState() => _DangNhapEmailPageState();
}

class _DangNhapEmailPageState extends State<DangNhapEmailPage> {
  final TextEditingController emailController = TextEditingController();
  final AuthService authService = AuthService();

  StreamSubscription<AuthState>? authSub;

  bool isGoogleLoading = false;
  bool isNavigating = false;

  bool get isValidEmail {
    final email = emailController.text.trim();
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();

    authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && !isNavigating) {
        isNavigating = true;

        if (!mounted) return;

        ScaffoldMessenger.of(context).clearSnackBars();

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.loading,
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    authSub?.cancel();
    super.dispose();
  }

  bool _isGoogleOAuthTabError(Object e) {
    final message = e.toString().toLowerCase();

    return message.contains('tab') ||
        message.contains('custom tabs') ||
        message.contains('browser') ||
        message.contains('cancel') ||
        message.contains('cancelled') ||
        message.contains('canceled') ||
        message.contains('closed') ||
        message.contains('not found') ||
        message.contains('không tìm thấy') ||
        message.contains('khong tim thay') ||
        message.contains('màn hình') ||
        message.contains('man hinh');
  }

  Future<void> handleGoogleLogin() async {
    if (isGoogleLoading) return;

    setState(() {
      isGoogleLoading = true;
    });

    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;

      if (_isGoogleOAuthTabError(e)) {
        return;
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  void goToPasswordEmail() {
    if (!isValidEmail) return;

    Navigator.pushNamed(
      context,
      AppRoutes.passwordEmail,
      arguments: {'email': emailController.text.trim()},
    );
  }

  @override
  Widget build(BuildContext context) {
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
            final buttonHeight = isSmallPhone ? 50.0 : 54.0;
            final fieldVerticalPadding = isSmallPhone ? 14.0 : 16.0;

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
                          'Nhập Email của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: emailController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: blue,
                          decoration: InputDecoration(
                            hintText: 'Địa chỉ Email',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: field,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: fieldVerticalPadding,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.loginPhone,
                            );
                          },
                          child: const Text(
                            'Sử dụng số điện thoại >',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: OutlinedButton.icon(
                            onPressed: isGoogleLoading
                                ? null
                                : handleGoogleLogin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            icon: const Icon(Icons.g_mobiledata, size: 34),
                            label: Text(
                              isGoogleLoading
                                  ? 'Đang mở Google...'
                                  : 'Tiếp tục với Google',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Bằng cách nhấn vào nút Tiếp tục,\n'
                          'bạn đồng ý với chúng tôi Điều khoản\n'
                          'dịch vụ và Chính sách quyền riêng tư',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _primaryButton(
                          label: 'Tiếp tục',
                          color: isValidEmail ? blue : Colors.grey,
                          height: buttonHeight,
                          onTap: isValidEmail ? goToPasswordEmail : null,
                        ),
                        const SizedBox(height: 24),
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
        onTap: isGoogleLoading ? null : () => Navigator.pop(context),
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
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
