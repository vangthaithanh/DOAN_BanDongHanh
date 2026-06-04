import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';

class DangKiSdtPage extends StatefulWidget {
  const DangKiSdtPage({super.key});

  @override
  State<DangKiSdtPage> createState() => _DangKiSdtPageState();
}

class _DangKiSdtPageState extends State<DangKiSdtPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final AuthService authService = AuthService();

  bool otpSent = false;

  bool get isValidPhone {
    return authService.isValidVietnamPhone(phoneController.text);
  }

  bool get isValidOtp {
    return authService.verifyOtpDemo(otpController.text);
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!isValidPhone) {
      _showMessage('Số điện thoại không hợp lệ');
      return;
    }

    setState(() {
      otpSent = true;
      otpController.clear();
    });

    _showMessage('OTP demo là ${AuthService.demoOtp}');
  }

  void _continueNext() {
    if (!otpSent) {
      _sendOtp();
      return;
    }

    if (!isValidOtp) {
      _showMessage('OTP không đúng. Mã demo là ${AuthService.demoOtp}');
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.registerPasswordPhone,
      arguments: {'phone': phoneController.text.trim()},
    );
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
                          'Nhập Số điện thoại của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: phoneController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+]'),
                            ),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Số điện thoại',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: field,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            suffixIcon: TextButton(
                              onPressed: isValidPhone ? _sendOtp : null,
                              child: const Text('OTP'),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (otpSent) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: otpController,
                            onChanged: (_) => setState(() {}),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Nhập OTP',
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
                        ],
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.registerEmail,
                            );
                          },
                          child: const Text(
                            'Sử dụng Email >',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallPhone ? 90 : 130),
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
                          label: otpSent ? 'Xác nhận OTP' : 'Gửi OTP',
                          color: isValidPhone ? blue : Colors.grey,
                          height: buttonHeight,
                          onTap: isValidPhone ? _continueNext : null,
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
