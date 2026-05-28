class KhoanhKhacMau {
  final String duongDanAnh;
  final String tenNguoiDang;
  final String thoiGian;
  final bool laAnhMay;

  const KhoanhKhacMau({
    required this.duongDanAnh,
    required this.tenNguoiDang,
    required this.thoiGian,
    this.laAnhMay = false,
  });
}

class KhoLuuKhoanhKhacTam {
  KhoLuuKhoanhKhacTam._();

  static final List<String> _danhSachAnhDaChup = [];

  static List<String> get danhSachAnhDaChup {
    return List.unmodifiable(_danhSachAnhDaChup);
  }

  static void themAnh(String duongDanAnh) {
    if (duongDanAnh.trim().isEmpty) return;

    if (_danhSachAnhDaChup.contains(duongDanAnh)) return;

    _danhSachAnhDaChup.insert(0, duongDanAnh);
  }
}

const List<KhoanhKhacMau> danhSachKhoanhKhacMauGoc = [
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh1.jpg',
    tenNguoiDang: 'BongAnhHung',
    thoiGian: '3 tiếng trước',
  ),
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh2.jpg',
    tenNguoiDang: 'Buji',
    thoiGian: '2 tiếng trước',
  ),
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh3.jpg',
    tenNguoiDang: 'BongAnhHung',
    thoiGian: '1 tiếng trước',
  ),
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh1.jpg',
    tenNguoiDang: 'Buji',
    thoiGian: '3 tiếng trước',
  ),
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh2.jpg',
    tenNguoiDang: 'BongAnhHung',
    thoiGian: '2 tiếng trước',
  ),
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh3.jpg',
    tenNguoiDang: 'Buji',
    thoiGian: '1 tiếng trước',
  ),
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh2.jpg',
    tenNguoiDang: 'BongAnhHung',
    thoiGian: '3 tiếng trước',
  ),
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh1.jpg',
    tenNguoiDang: 'Buji',
    thoiGian: '2 tiếng trước',
  ),
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh3.jpg',
    tenNguoiDang: 'BongAnhHung',
    thoiGian: '1 tiếng trước',
  ),
];

List<KhoanhKhacMau> layDanhSachKhoanhKhacHienThi() {
  final danhSachAnhDaChup = KhoLuuKhoanhKhacTam.danhSachAnhDaChup.map((path) {
    return KhoanhKhacMau(
      duongDanAnh: path,
      tenNguoiDang: 'Xuthu',
      thoiGian: 'Vừa xong',
      laAnhMay: true,
    );
  }).toList();

  return [
    ...danhSachAnhDaChup,
    ...danhSachKhoanhKhacMauGoc,
  ];
}