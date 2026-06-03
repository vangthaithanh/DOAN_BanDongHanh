import 'package:flutter/material.dart';

import '../models/dia_diem_model.dart';

const List<DiaDiemModel> mockDiaDiems = [
  DiaDiemModel(
    maDiaDiem: 1,
    maLoai: 1,
    tenDiaDiem: 'Bãi biển Mỹ Khê',
    tinhThanh: 'Đà Nẵng',
    quanHuyen: 'Sơn Trà',
    diaChi: 'Võ Nguyên Giáp, Sơn Trà, Đà Nẵng',
    viDo: 16.061800,
    kinhDo: 108.245000,
    gioMoCua: 'Cả ngày',
    mucGia: 0,
    diemTrungBinh: 4.5,
    tongDanhGia: 30,
    tongLuotLuu: 1300,
    tuKhoa: 'bien, checkin, da nang, my khe',
    moTa:
        'Bãi biển nổi tiếng với bờ cát dài, nước trong và nhiều hoạt động vui chơi. Phù hợp để đi dạo, chụp ảnh, tắm biển và ngắm hoàng hôn.',
    trangThai: 'active',
    khoangCachHienThi: '5 km',
    thoiGianUocTinhHienThi: '15 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 1,
        maDiaDiem: 1,
        loaiMedia: 'image',
        duongDan: 'assets/images/anh1.jpg',
      ),
      MediaDiaDiemModel(
        maMedia: 2,
        maDiaDiem: 1,
        loaiMedia: 'image',
        duongDan: 'assets/images/anh2.jpg',
      ),
      MediaDiaDiemModel(
        maMedia: 3,
        maDiaDiem: 1,
        loaiMedia: 'image',
        duongDan: 'assets/images/anh3.jpg',
      ),
    ],
  ),
  DiaDiemModel(
    maDiaDiem: 2,
    maLoai: 1,
    tenDiaDiem: 'Cầu Rồng',
    tinhThanh: 'Đà Nẵng',
    quanHuyen: 'Hải Châu',
    diaChi: 'Đường Nguyễn Văn Linh, Hải Châu, Đà Nẵng',
    viDo: 16.061200,
    kinhDo: 108.227700,
    gioMoCua: 'Cả ngày',
    mucGia: 0,
    diemTrungBinh: 4.5,
    tongDanhGia: 52,
    tongLuotLuu: 2100,
    tuKhoa: 'cau rong, song han, da nang',
    moTa:
        'Địa điểm biểu tượng của Đà Nẵng, nổi bật vào buổi tối và cuối tuần. Có thể kết hợp tham quan sông Hàn, chợ đêm và khu ăn uống xung quanh.',
    trangThai: 'active',
    khoangCachHienThi: '3 km',
    thoiGianUocTinhHienThi: '10 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 4,
        maDiaDiem: 2,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac1.jpg',
      ),
      MediaDiaDiemModel(
        maMedia: 5,
        maDiaDiem: 2,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac2.jpg',
      ),
      MediaDiaDiemModel(
        maMedia: 6,
        maDiaDiem: 2,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac3.jpg',
      ),
    ],
  ),
  DiaDiemModel(
    maDiaDiem: 3,
    maLoai: 2,
    tenDiaDiem: 'Bán đảo Sơn Trà',
    tinhThanh: 'Đà Nẵng',
    quanHuyen: 'Sơn Trà',
    diaChi: 'Sơn Trà, Đà Nẵng',
    viDo: 16.115000,
    kinhDo: 108.273000,
    gioMoCua: 'Cả ngày',
    mucGia: 0,
    diemTrungBinh: 4.6,
    tongDanhGia: 41,
    tongLuotLuu: 1800,
    tuKhoa: 'son tra, thien nhien, ngam canh',
    moTa:
        'Khu vực thiên nhiên có nhiều điểm ngắm cảnh đẹp, đường ven biển thoáng và nhiều góc chụp ảnh. Phù hợp với nhóm thích khám phá nhẹ.',
    trangThai: 'active',
    khoangCachHienThi: '9 km',
    thoiGianUocTinhHienThi: '25 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 7,
        maDiaDiem: 3,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac4.jpg',
      ),
      MediaDiaDiemModel(
        maMedia: 8,
        maDiaDiem: 3,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac5.jpg',
      ),
      MediaDiaDiemModel(
        maMedia: 9,
        maDiaDiem: 3,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac6.jpg',
      ),
    ],
  ),
];

DiaDiemModel timDiaDiemTheoId(int? id) {
  return mockDiaDiems.firstWhere(
    (item) => item.maDiaDiem == id,
    orElse: () => mockDiaDiems.first,
  );
}

class KhoDanhGiaDiaDiem extends ChangeNotifier {
  KhoDanhGiaDiaDiem._();

  static final KhoDanhGiaDiaDiem instance = KhoDanhGiaDiaDiem._();

  final List<DanhGiaDiaDiemModel> _danhSach = [
    DanhGiaDiaDiemModel(
      maDanhGia: 1,
      idNguoiDung: 1,
      maDiaDiem: 1,
      soSao: 5,
      noiDung: 'View đẹp, đi chiều mát rất ổn, có nhiều góc chụp hình.',
      trangThai: 'active',
      ngayTao: DateTime(2026, 5, 20),
      tenNguoiDung: 'Buji',
      media: const [
        MediaDanhGiaModel(
          maMedia: 1,
          maDanhGia: 1,
          loaiMedia: 'image',
          duongDan: 'assets/images/anh1.jpg',
        ),
        MediaDanhGiaModel(
          maMedia: 2,
          maDanhGia: 1,
          loaiMedia: 'image',
          duongDan: 'assets/images/anh2.jpg',
        ),
      ],
    ),
    DanhGiaDiaDiemModel(
      maDanhGia: 2,
      idNguoiDung: 2,
      maDiaDiem: 1,
      soSao: 4,
      noiDung: 'Không gian rộng, dễ tìm đường và hợp đi nhóm bạn.',
      trangThai: 'active',
      ngayTao: DateTime(2026, 5, 21),
      tenNguoiDung: 'Buji',
    ),
    DanhGiaDiaDiemModel(
      maDanhGia: 3,
      idNguoiDung: 3,
      maDiaDiem: 1,
      soSao: 5,
      noiDung: 'Giá cả ổn, cuối tuần hơi đông nhưng vẫn đáng đi.',
      trangThai: 'active',
      ngayTao: DateTime(2026, 5, 22),
      tenNguoiDung: 'Buji',
    ),
  ];

  List<DanhGiaDiaDiemModel> danhSachTheoDiaDiem(int maDiaDiem) {
    return _danhSach
        .where(
          (item) => item.maDiaDiem == maDiaDiem && item.trangThai == 'active',
        )
        .toList();
  }

  void themDanhGia({
    required int maDiaDiem,
    required int soSao,
    required String noiDung,
    List<String> hinhAnh = const [],
  }) {
    final now = DateTime.now();
    final maDanhGiaMoi = now.millisecondsSinceEpoch;

    _danhSach.insert(
      0,
      DanhGiaDiaDiemModel(
        maDanhGia: maDanhGiaMoi,
        idNguoiDung: 1,
        maDiaDiem: maDiaDiem,
        soSao: soSao,
        noiDung: noiDung,
        trangThai: 'active',
        ngayTao: now,
        tenNguoiDung: 'Bạn',
        media: hinhAnh.asMap().entries.map((entry) {
          return MediaDanhGiaModel(
            maMedia: maDanhGiaMoi + entry.key,
            maDanhGia: maDanhGiaMoi,
            loaiMedia: 'image',
            duongDan: entry.value,
            ngayTao: now,
          );
        }).toList(),
      ),
    );

    notifyListeners();
  }
}
