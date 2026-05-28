import 'package:flutter/material.dart';

class KhungQuenMatKhau extends StatelessWidget {
  final String tieuDe;
  final Widget noiDung;
  final bool choPhepTiepTuc;
  final VoidCallback? khiBamTiepTuc;
  final bool hienDieuKhoan;

  const KhungQuenMatKhau({
    super.key,
    required this.tieuDe,
    required this.noiDung,
    required this.choPhepTiepTuc,
    required this.khiBamTiepTuc,
    this.hienDieuKhoan = false,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF4AA8FF);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _backButton(context),

              const SizedBox(height: 56),

              Text(
                tieuDe,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 18),

              noiDung,

              const Spacer(),

              if (hienDieuKhoan) ...[
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
              ],

              _primaryButton(
                label: 'Tiếp tục',
                color: blue,
                onTap: choPhepTiepTuc ? khiBamTiepTuc : null,
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
          disabledBackgroundColor: color,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
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