import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';

class DangKiMatKhauSdtPage extends StatefulWidget {
  const DangKiMatKhauSdtPage({super.key});

  @override
  State<DangKiMatKhauSdtPage> createState() => _DangKiMatKhauSdtPageState();
}

class _DangKiMatKhauSdtPageState extends State<DangKiMatKhauSdtPage> {
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

  bool get isValidPassword {
    return passwordController.text.trim().length >= 8;
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  void _continueNext(String phone) {
    if (!isValidPassword) return;

    Navigator.pushNamed(
      context,
      AppRoutes.registerNamePhone,
      arguments: {'phone': phone, 'password': passwordController.text.trim()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final phone = args?['phone'] as String? ?? '';

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
                          'Chọn một mật khẩu',
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
                          controller: passwordController,
                          onChanged: (_) => setState(() {}),
                          obscureText: obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Mật khẩu',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: field,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
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
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Mật khẩu có ít nhất ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: '8 kí tự',
                                style: TextStyle(
                                  color: blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallPhone ? 120 : 170),
                        _primaryButton(
                          label: 'Tiếp tục',
                          color: isValidPassword ? blue : Colors.grey,
                          height: buttonHeight,
                          onTap: isValidPassword
                              ? () => _continueNext(phone)
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
