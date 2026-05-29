class KhoanhKhacMau {
  final String duongDanAnh;
  final String tenNguoiDang;
  final String thoiGian;
  final bool laAnhMay;
  final String? viTri;

  const KhoanhKhacMau({
    required this.duongDanAnh,
    required this.tenNguoiDang,
    required this.thoiGian,
    this.laAnhMay = false,
    this.viTri,
  });
}

class KhoLuuKhoanhKhacTam {
  KhoLuuKhoanhKhacTam._();

  static final List<KhoanhKhacMau>
  _danhSachAnhDaChup = [];

  static List<KhoanhKhacMau>
  get danhSachAnhDaChup {
    return List.unmodifiable(
      _danhSachAnhDaChup,
    );
  }

  static void themAnh({
    required String duongDanAnh,
    String? viTri,
  }) {
    if (duongDanAnh.trim().isEmpty) return;

    final daTonTai = _danhSachAnhDaChup.any(
          (e) => e.duongDanAnh == duongDanAnh,
    );

    if (daTonTai) return;

    _danhSachAnhDaChup.insert(
      0,
      KhoanhKhacMau(
        duongDanAnh: duongDanAnh,
        tenNguoiDang: 'Xuthu',
        thoiGian: 'Vừa xong',
        laAnhMay: true,
        viTri: viTri,
      ),
    );
  }
}

const List<KhoanhKhacMau>
danhSachKhoanhKhacMauGoc = [
  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh1.jpg',
    tenNguoiDang: 'BongAnhHung',
    thoiGian: '3 tiếng trước',
    viTri: 'AEON Mall Bình Tân',
  ),

  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh2.jpg',
    tenNguoiDang: 'Buji',
    thoiGian: '2 tiếng trước',
    viTri: 'Landmark 81',
  ),

  KhoanhKhacMau(
    duongDanAnh: 'assets/images/anh3.jpg',
    tenNguoiDang: 'BongAnhHung',
    thoiGian: '1 tiếng trước',
    viTri: 'Đầm Sen',
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
];

List<KhoanhKhacMau>
layDanhSachKhoanhKhacHienThi() {
  return [
    ...KhoLuuKhoanhKhacTam
        .danhSachAnhDaChup,

    ...danhSachKhoanhKhacMauGoc,
  ];
}