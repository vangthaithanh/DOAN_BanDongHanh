import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/models/du_lieu_quen_matkhau.dart';
import '../../data/models/phuong_thuc_quen_matkhau.dart';
import '../widgets/khung_quen_matkhau.dart';
import '../widgets/o_nhap_quen_matkhau.dart';

class QuenMatKhauEmail extends StatefulWidget {
  const QuenMatKhauEmail({super.key});

  @override
  State<QuenMatKhauEmail> createState() => _QuenMatKhauEmailState();
}

class _QuenMatKhauEmailState extends State<QuenMatKhauEmail> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _emailHopLe = false;

  bool _kiemTraEmail(String value) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    return regex.hasMatch(value.trim());
  }

  void _xuLyThayDoiEmail(String value) {
    setState(() {
      _emailHopLe = _kiemTraEmail(value);
    });
  }

  void _guiOtpVaDiTiep() {
    final email = _emailController.text.trim();

    try {
      final otp = _authService.requestEmailOtpDemo(email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP demo gửi về Gmail $email là $otp'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );

      final duLieu = DuLieuQuenMatKhau(
        phuongThuc: PhuongThucQuenMatKhau.email,
        giaTriLienHe: email,
        gmailNhanOtp: email,
      );

      Navigator.pushNamed(context, AppRoutes.quenMatKhauOtp, arguments: duLieu);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KhungQuenMatKhau(
      tieuDe: 'Nhập Gmail của bạn',
      hienDieuKhoan: false,
      choPhepTiepTuc: _emailHopLe,
      khiBamTiepTuc: _guiOtpVaDiTiep,
      noiDung: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ONhapQuenMatKhau(
            controller: _emailController,
            goiY: 'Địa chỉ Gmail',
            kieuBanPhim: TextInputType.emailAddress,
            khiThayDoi: _xuLyThayDoiEmail,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, AppRoutes.quenMatKhauSdt);
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
          const SizedBox(height: 10),
          const Text(
            'OTP demo sẽ hiện bằng thông báo trên app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
