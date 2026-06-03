import 'dart:async';

import 'package:do_an/app/routes/app_routes.dart';
import 'package:do_an/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DangNhapEmailPage extends StatefulWidget {
  const DangNhapEmailPage({super.key});

  @override
  State<DangNhapEmailPage> createState() => _DangNhapEmailPageState();
}

class _DangNhapEmailPageState extends State<DangNhapEmailPage> {
  final TextEditingController emailController = TextEditingController();

  // THÊM MỚI: service xử lý đăng nhập Supabase
  final AuthService authService = AuthService();

  // THÊM MỚI: trạng thái loading cho nút Google
  bool isGoogleLoading = false;

  // THÊM MỚI: lắng nghe khi Google login xong quay lại app
  StreamSubscription<AuthState>? authSub;

  bool get isValidEmail {
    final email = emailController.text.trim();
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();

    // THÊM MỚI:
    // Khi đăng nhập Google thành công, Supabase bắn event signedIn.
    // Lúc đó tạo profile nếu chưa có rồi chuyển vào loading/home.
    authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      if (data.event == AuthChangeEvent.signedIn) {
        try {
          await authService.ensureProfileAfterOAuth();
        } catch (e) {
          debugPrint('ensureProfileAfterOAuth error: $e');
        }

        if (!mounted) return;

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

    // THÊM MỚI: hủy listener để tránh rò rỉ bộ nhớ
    authSub?.cancel();

    super.dispose();
  }

  // THÊM MỚI: hàm xử lý bấm nút Google
  Future<void> handleGoogleLogin() async {
    if (isGoogleLoading) return;

    setState(() {
      isGoogleLoading = true;
    });

    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF4AA8FF);
    const field = Color(0xFF2E2E31);

    return Scaffold(
      backgroundColor: Colors.black,

      // SỬA: tránh lỗi bottom overflow khi bàn phím bật
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        // SỬA: bọc SingleChildScrollView để màn hình cuộn được khi bàn phím hiện
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _backButton(context),

              const SizedBox(height: 56),

              const Text(
                'Nhập Email của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: emailController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Địa chỉ Email',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: field,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
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
                  Navigator.pushReplacementNamed(context, AppRoutes.loginPhone);
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

              // THÊM MỚI: nút đăng nhập Google
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: isGoogleLoading ? null : handleGoogleLogin,
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
                onTap: isValidEmail
                    ? () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.passwordEmail,
                          arguments: {'email': emailController.text.trim()},
                        );
                      }
                    : null,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => Navigator.pop(context),
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
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 54,
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
