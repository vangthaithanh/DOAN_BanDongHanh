import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/models/du_lieu_quen_matkhau.dart';
import '../../data/models/phuong_thuc_quen_matkhau.dart';
import '../widgets/khung_quen_matkhau.dart';
import '../widgets/o_nhap_quen_matkhau.dart';

class QuenMatKhauMoi extends StatefulWidget {
  final DuLieuQuenMatKhau duLieu;

  const QuenMatKhauMoi({super.key, required this.duLieu});

  @override
  State<QuenMatKhauMoi> createState() => _QuenMatKhauMoiState();
}

class _QuenMatKhauMoiState extends State<QuenMatKhauMoi> {
  final TextEditingController _matKhauController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _matKhauHopLe = false;
  bool _dangXuLy = false;

  void _xuLyThayDoiMatKhau(String value) {
    setState(() {
      _matKhauHopLe = value.trim().length >= 8;
    });
  }

  Future<void> _hoanTatDoiMatKhau() async {
    if (!_matKhauHopLe || _dangXuLy) {
      return;
    }

    if (widget.duLieu.otp != AuthService.demoOtp) {
      _showMessage('OTP không hợp lệ');
      return;
    }

    setState(() {
      _dangXuLy = true;
    });

    try {
      await _authService.resetPasswordDemo(
        newPassword: _matKhauController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công'),
          backgroundColor: Color(0xFF4AA8FF),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );

      final routeDangNhap =
          widget.duLieu.phuongThuc == PhuongThucQuenMatKhau.email
          ? AppRoutes.loginEmail
          : AppRoutes.loginPhone;

      Navigator.pushNamedAndRemoveUntil(
        context,
        routeDangNhap,
        (route) => false,
      );
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }

    if (mounted) {
      setState(() {
        _dangXuLy = false;
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
  void dispose() {
    _matKhauController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KhungQuenMatKhau(
      tieuDe: 'Chọn một mật khẩu',
      hienDieuKhoan: false,
      choPhepTiepTuc: _matKhauHopLe && !_dangXuLy,
      khiBamTiepTuc: _hoanTatDoiMatKhau,
      noiDung: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ONhapQuenMatKhau(
            controller: _matKhauController,
            goiY: _dangXuLy ? 'Đang đổi mật khẩu...' : 'Mật khẩu mới',
            anNoiDung: true,
            khiThayDoi: _xuLyThayDoiMatKhau,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: '8 kí tự',
                  style: TextStyle(
                    color: Color(0xFF4AA8FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Lưu ý: đây là luồng demo OTP. App sẽ báo đổi mật khẩu thành công theo yêu cầu giao diện.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
