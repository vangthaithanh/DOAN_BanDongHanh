import 'phuong_thuc_quen_matkhau.dart';

class DuLieuQuenMatKhau {
  final PhuongThucQuenMatKhau phuongThuc;
  final String giaTriLienHe;
  final String? gmailNhanOtp;
  final String? otp;

  const DuLieuQuenMatKhau({
    required this.phuongThuc,
    required this.giaTriLienHe,
    this.gmailNhanOtp,
    this.otp,
  });

  DuLieuQuenMatKhau copyWith({
    PhuongThucQuenMatKhau? phuongThuc,
    String? giaTriLienHe,
    String? gmailNhanOtp,
    String? otp,
  }) {
    return DuLieuQuenMatKhau(
      phuongThuc: phuongThuc ?? this.phuongThuc,
      giaTriLienHe: giaTriLienHe ?? this.giaTriLienHe,
      gmailNhanOtp: gmailNhanOtp ?? this.gmailNhanOtp,
      otp: otp ?? this.otp,
    );
  }
}
