import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/models/du_lieu_quen_matkhau.dart';
import '../../data/models/phuong_thuc_quen_matkhau.dart';
import '../widgets/khung_quen_matkhau.dart';
import '../widgets/o_nhap_quen_matkhau.dart';

class QuenMatKhauMoi extends StatefulWidget {
  final DuLieuQuenMatKhau duLieu;

  const QuenMatKhauMoi({
    super.key,
    required this.duLieu,
  });

  @override
  State<QuenMatKhauMoi> createState() => _QuenMatKhauMoiState();
}

class _QuenMatKhauMoiState extends State<QuenMatKhauMoi> {
  final TextEditingController _matKhauController = TextEditingController();

  bool _matKhauHopLe = false;

  void _xuLyThayDoiMatKhau(String value) {
    setState(() {
      _matKhauHopLe = value.trim().length >= 8;
    });
  }

  void _hoanTatDoiMatKhau() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đổi mật khẩu thành công demo'),
        backgroundColor: Color(0xFF4AA8FF),
      ),
    );

    final routeDangNhap = widget.duLieu.phuongThuc == PhuongThucQuenMatKhau.email
        ? AppRoutes.loginEmail
        : AppRoutes.loginPhone;

    Navigator.pushNamedAndRemoveUntil(
      context,
      routeDangNhap,
          (route) => false,
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
      choPhepTiepTuc: _matKhauHopLe,
      khiBamTiepTuc: _hoanTatDoiMatKhau,
      noiDung: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ONhapQuenMatKhau(
            controller: _matKhauController,
            goiY: 'Mật khẩu',
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
        ],
      ),
    );
  }
}