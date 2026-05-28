import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/models/du_lieu_quen_matkhau.dart';
import '../../data/models/phuong_thuc_quen_matkhau.dart';
import '../widgets/khung_quen_matkhau.dart';
import '../widgets/o_nhap_quen_matkhau.dart';

class QuenMatKhauSdt extends StatefulWidget {
  const QuenMatKhauSdt({super.key});

  @override
  State<QuenMatKhauSdt> createState() => _QuenMatKhauSdtState();
}

class _QuenMatKhauSdtState extends State<QuenMatKhauSdt> {
  final TextEditingController _sdtController = TextEditingController();

  bool _sdtHopLe = false;

  bool _kiemTraSdt(String value) {
    final text = value.trim();
    final regex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    return regex.hasMatch(text);
  }

  void _xuLyThayDoiSdt(String value) {
    setState(() {
      _sdtHopLe = _kiemTraSdt(value);
    });
  }

  void _diDenNhapOtp() {
    final duLieu = DuLieuQuenMatKhau(
      phuongThuc: PhuongThucQuenMatKhau.sdt,
      giaTriLienHe: _sdtController.text.trim(),
    );

    Navigator.pushNamed(
      context,
      AppRoutes.quenMatKhauOtp,
      arguments: duLieu,
    );
  }

  @override
  void dispose() {
    _sdtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KhungQuenMatKhau(
      tieuDe: 'Nhập Số điện thoại của bạn',
      hienDieuKhoan: false,
      choPhepTiepTuc: _sdtHopLe,
      khiBamTiepTuc: _diDenNhapOtp,
      noiDung: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ONhapQuenMatKhau(
            controller: _sdtController,
            goiY: 'Số điện thoại',
            kieuBanPhim: TextInputType.phone,
            boLocNhap: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              LengthLimitingTextInputFormatter(12),
            ],
            khiThayDoi: _xuLyThayDoiSdt,
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.quenMatKhauEmail,
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
        ],
      ),
    );
  }
}