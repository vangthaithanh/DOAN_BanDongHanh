import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/models/du_lieu_quen_matkhau.dart';
import '../widgets/khung_quen_matkhau.dart';

class QuenMatKhauOtp extends StatefulWidget {
  final DuLieuQuenMatKhau duLieu;

  const QuenMatKhauOtp({super.key, required this.duLieu});

  @override
  State<QuenMatKhauOtp> createState() => _QuenMatKhauOtpState();
}

class _QuenMatKhauOtpState extends State<QuenMatKhauOtp> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _giayConLai = 39;

  String get _maOtp {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool get _daNhapDuOtp {
    return _maOtp.length == 6;
  }

  @override
  void initState() {
    super.initState();
    _batDauDemNguoc();
  }

  void _batDauDemNguoc() {
    _timer?.cancel();

    setState(() {
      _giayConLai = 39;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_giayConLai <= 0) {
        timer.cancel();
        return;
      }

      if (!mounted) return;

      setState(() {
        _giayConLai--;
      });
    });
  }

  void _xuLyNhapOtp(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  void _guiLaiOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }

    _focusNodes.first.requestFocus();
    _batDauDemNguoc();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã gửi lại OTP demo: ${AuthService.demoOtp}'),
        backgroundColor: const Color(0xFF43A9F5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _diDenChonMatKhauMoi() {
    if (_maOtp != AuthService.demoOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP không đúng. Mã demo là ${AuthService.demoOtp}'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.quenMatKhauMoi,
      arguments: widget.duLieu.copyWith(otp: _maOtp),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _otpControllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gmail = widget.duLieu.gmailNhanOtp ?? widget.duLieu.giaTriLienHe;

    return KhungQuenMatKhau(
      tieuDe: 'Nhập mã OTP',
      hienDieuKhoan: false,
      choPhepTiepTuc: _daNhapDuOtp,
      khiBamTiepTuc: _diDenChonMatKhauMoi,
      noiDung: Column(
        children: [
          Text(
            'Mã OTP đã gửi về:\n$gmail',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: _oNhapOtp(index),
              );
            }),
          ),
          const SizedBox(height: 13),
          _dongGuiLaiOtp(),
        ],
      ),
    );
  }

  Widget _oNhapOtp(int index) {
    return SizedBox(
      width: 47,
      height: 32,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        cursorColor: Colors.white,
        obscureText: true,
        obscuringCharacter: '*',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          hintText: '*',
          hintStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          filled: true,
          fillColor: const Color(0xFF2D2D2F),
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          _xuLyNhapOtp(value, index);
        },
      ),
    );
  }

  Widget _dongGuiLaiOtp() {
    if (_giayConLai > 0) {
      return Text(
        'Gửi lại OTP trong ${_giayConLai}s',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return InkWell(
      onTap: _guiLaiOtp,
      child: const Text(
        'Gửi lại OTP',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF43A9F5),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
