import 'package:flutter/material.dart';

class DangKiSdtPage extends StatelessWidget {
  const DangKiSdtPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                'Nhập Số điện thoại của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Số điện thoại',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: field,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/dangki-email');
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
              const Spacer(),
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
                color: blue,
                onTap: () {
                  Navigator.pushNamed(context, '/dangki-matkhau-sdt');
                },
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
    required VoidCallback onTap,
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