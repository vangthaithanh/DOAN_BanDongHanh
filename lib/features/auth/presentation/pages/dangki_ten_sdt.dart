import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';

class DangKiTenSdtPage extends StatefulWidget {
  const DangKiTenSdtPage({super.key});

  @override
  State<DangKiTenSdtPage> createState() => _DangKiTenSdtPageState();
}

class _DangKiTenSdtPageState extends State<DangKiTenSdtPage> {
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

  Future<void> _signUpPhone({
    required String phone,
    required String password,
  }) async {
    final nickname = nicknameController.text.trim();

    if (!isValidNickname) {
      _showMessage('Biệt danh tối thiểu 3 ký tự');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authService.signUpWithPhoneDemo(
        phone: phone,
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
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final phone = args?['phone'] as String? ?? '';
    final password = args?['password'] as String? ?? '';

    const blue = Color(0xFF4AA8FF);
    const field = Color(0xFF2E2E31);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallPhone = constraints.maxWidth < 360;
            final horizontalPadding = isSmallPhone ? 20.0 : 24.0;
            final topGap = isSmallPhone ? 38.0 : 56.0;
            final titleSize = isSmallPhone ? 25.0 : 28.0;
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
                          'Đặt biệt danh',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          phone,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: nicknameController,
                          onChanged: (_) => setState(() {}),
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
                        SizedBox(height: isSmallPhone ? 100 : 140),
                        _primaryButton(
                          label: isLoading ? 'Đang tạo...' : 'Tiếp tục',
                          color: isValidNickname && !isLoading
                              ? blue
                              : Colors.grey,
                          height: buttonHeight,
                          onTap: isValidNickname && !isLoading
                              ? () => _signUpPhone(
                                  phone: phone,
                                  password: password,
                                )
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
