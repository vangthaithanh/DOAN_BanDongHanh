import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';

/// NOTE SỬA:
/// Màn đặt biệt danh + tạo tài khoản.
/// Responsive:
/// - LayoutBuilder
/// - SingleChildScrollView
/// - Không fix cứng.
/// Logic:
/// - Gọi AuthService.signUpWithEmail().
/// - Sau khi tạo xong chuyển sang màn thêm avatar.
class DangKiTenEmailPage extends StatefulWidget {
  const DangKiTenEmailPage({super.key});

  @override
  State<DangKiTenEmailPage> createState() => _DangKiTenEmailPageState();
}

class _DangKiTenEmailPageState extends State<DangKiTenEmailPage> {
  final TextEditingController nicknameController = TextEditingController();
  final AuthService authService = AuthService();

  bool isLoading = false;

  bool get isValidNickname {
    return nicknameController.text.trim().length >= 3;
  }

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> handleSignUp({
    required String email,
    required String password,
  }) async {
    final nickname = nicknameController.text.trim();

    if (nickname.length < 3) {
      _showMessage('Biệt danh tối thiểu 3 ký tự');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      await authService.signUpWithEmail(
        email: email,
        password: password,
        nickname: nickname,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamed(
        context,
        AppRoutes.addAvatar,
        arguments: {'nickname': nickname},
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _friendlyError(Object e) {
    final message = e.toString();

    if (message.contains('infinite recursion')) {
      return 'RLS bảng profiles đang bị lặp. Kiểm tra lại policy profiles.';
    }

    if (message.contains('row-level security')) {
      return 'RLS chưa cho phép tạo hồ sơ.';
    }

    if (message.contains('duplicate') ||
        message.contains('already') ||
        message.contains('Biệt danh đã tồn tại')) {
      return 'Biệt danh hoặc email đã tồn tại';
    }

    if (message.contains('User already registered')) {
      return 'Email này đã được đăng ký';
    }

    return message.replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
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
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final email = args?['email'] as String? ?? '';
    final password = args?['password'] as String? ?? '';

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
            final topGap = isSmallPhone ? 36.0 : 56.0;
            final titleSize = isSmallPhone ? 25.0 : 28.0;
            final fieldVerticalPadding = isSmallPhone ? 14.0 : 16.0;
            final buttonHeight = isSmallPhone ? 50.0 : 54.0;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                16,
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
                          'Đặt biệt danh',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: nicknameController,
                          onChanged: (_) {
                            setState(() {});
                          },
                          enabled: !isLoading,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9_À-ỹ\s]'),
                            ),
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Biệt danh',
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
                        const SizedBox(height: 10),
                        const Text(
                          'Biệt danh tối thiểu 3 ký tự và không được trùng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        SizedBox(height: isSmallPhone ? 90 : 130),
                        SizedBox(
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: isValidNickname && !isLoading
                                ? () {
                                    handleSignUp(
                                      email: email,
                                      password: password,
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isValidNickname && !isLoading
                                  ? blue
                                  : Colors.grey,
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
                                : const Text(
                                    'Tiếp tục',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
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
}
