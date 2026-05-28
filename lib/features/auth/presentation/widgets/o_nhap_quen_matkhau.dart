import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ONhapQuenMatKhau extends StatelessWidget {
  final TextEditingController controller;
  final String goiY;
  final TextInputType kieuBanPhim;
  final bool anNoiDung;
  final List<TextInputFormatter>? boLocNhap;
  final ValueChanged<String>? khiThayDoi;

  const ONhapQuenMatKhau({
    super.key,
    required this.controller,
    required this.goiY,
    this.kieuBanPhim = TextInputType.text,
    this.anNoiDung = false,
    this.boLocNhap,
    this.khiThayDoi,
  });

  @override
  Widget build(BuildContext context) {
    const field = Color(0xFF2E2E31);

    return TextField(
      controller: controller,
      keyboardType: kieuBanPhim,
      obscureText: anNoiDung,
      inputFormatters: boLocNhap,
      onChanged: khiThayDoi,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: goiY,
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
    );
  }
}