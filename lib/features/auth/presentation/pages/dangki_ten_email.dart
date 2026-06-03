import 'package:do_an/app/routes/app_routes.dart';
import 'package:do_an/core/services/auth_service.dart';
import 'package:flutter/material.dart';

class DangKiTenEmailPage extends StatefulWidget {
  const DangKiTenEmailPage({super.key});

  @override
  State<DangKiTenEmailPage> createState() => _DangKiTenEmailPageState();
}

class _DangKiTenEmailPageState extends State<DangKiTenEmailPage> {
  final TextEditingController nicknameController = TextEditingController();
  final AuthService authService = AuthService();

  bool isLoading = false;

  bool get isValidNickname => nicknameController.text.trim().length >= 3;

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> handleSignUp(String email, String password) async {
    final nickname = nicknameController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      await authService.signUpWithEmail(
        email: email,
        password: password,
        nickname: nickname,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        AppRoutes.addAvatar,
        arguments: {'nickname': nickname},
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final email = args?['email'] as String? ?? '';
    final password = args?['password'] as String? ?? '';

    const blue = Color(0xFF4AA8FF);
    const field = Color(0xFF2E2E31);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _backButton(context),
              const SizedBox(height: 56),
              const Text(
                'Đặt biệt danh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nicknameController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Biệt danh',
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
              const SizedBox(height: 10),
              const Text(
                'Biệt danh tối thiểu 3 ký tự và không được trùng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const Spacer(),
              _primaryButton(
                label: isLoading ? 'Đang tạo tài khoản...' : 'Tiếp tục',
                color: isValidNickname && !isLoading ? blue : Colors.grey,
                onTap: isValidNickname && !isLoading
                    ? () => handleSignUp(email, password)
                    : null,
              ),
              const SizedBox(height: 12),
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
