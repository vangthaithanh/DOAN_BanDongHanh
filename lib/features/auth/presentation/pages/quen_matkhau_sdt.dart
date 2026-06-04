import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
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
  final TextEditingController _gmailController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _sdtHopLe = false;
  bool _gmailHopLe = false;

  bool get _choPhepTiepTuc {
    return _sdtHopLe && _gmailHopLe;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      final phone = args?['phone'] as String? ?? '';

      if (phone.isNotEmpty) {
        _sdtController.text = phone;
        _xuLyThayDoiSdt(phone);
      }
    });
  }

  bool _kiemTraEmail(String value) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    return regex.hasMatch(value.trim());
  }

  void _xuLyThayDoiSdt(String value) {
    setState(() {
      _sdtHopLe = _authService.isValidVietnamPhone(value);
    });
  }

  void _xuLyThayDoiGmail(String value) {
    setState(() {
      _gmailHopLe = _kiemTraEmail(value);
    });
  }

  void _guiOtpVaDiTiep() {
    final phone = _sdtController.text.trim();
    final gmail = _gmailController.text.trim();

    try {
      final otp = _authService.requestPhoneForgotOtpDemo(
        phone: phone,
        gmail: gmail,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP demo gửi về Gmail $gmail là $otp'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );

      final duLieu = DuLieuQuenMatKhau(
        phuongThuc: PhuongThucQuenMatKhau.sdt,
        giaTriLienHe: phone,
        gmailNhanOtp: gmail,
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
    _sdtController.dispose();
    _gmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KhungQuenMatKhau(
      tieuDe: 'Quên mật khẩu SĐT',
      hienDieuKhoan: false,
      choPhepTiepTuc: _choPhepTiepTuc,
      khiBamTiepTuc: _guiOtpVaDiTiep,
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
          ONhapQuenMatKhau(
            controller: _gmailController,
            goiY: 'Gmail nhận OTP',
            kieuBanPhim: TextInputType.emailAddress,
            khiThayDoi: _xuLyThayDoiGmail,
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
              'Sử dụng Gmail >',
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
