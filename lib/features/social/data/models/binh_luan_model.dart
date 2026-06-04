class BinhLuanModel {
  final int id;
  final int postId;
  final String tenNguoiBinhLuan;
  final String? anhDaiDienNguoiBinhLuan;
  final String? tenNguoiDuocTraLoi;
  final String thoiGian;
  final String noiDung;
  final List<BinhLuanModel> danhSachTraLoi;

  const BinhLuanModel({
    required this.id,
    required this.postId,
    required this.tenNguoiBinhLuan,
    this.anhDaiDienNguoiBinhLuan,
    this.tenNguoiDuocTraLoi,
    required this.thoiGian,
    required this.noiDung,
    this.danhSachTraLoi = const [],
  });
}
