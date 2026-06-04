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
    tuKhoa: 'bien, bien dao, checkin, da nang, my khe, nghi duong, hot',
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
    maLoai: 5,
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
    tuKhoa: 'cau rong, song han, da nang, checkin, giai tri, hot',
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
    tuKhoa: 'son tra, thien nhien, nui rung, ngam canh, bien, checkin',
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
  DiaDiemModel(
    maDiaDiem: 4,
    maLoai: 4,
    tenDiaDiem: 'Chợ Bến Thành',
    tinhThanh: 'TP.HCM',
    quanHuyen: 'Quận 1',
    diaChi: 'Lê Lợi, Phường Bến Thành, Quận 1, TP.HCM',
    viDo: 10.772500,
    kinhDo: 106.698000,
    gioMoCua: '07:00 - 19:00',
    mucGia: 0,
    diemTrungBinh: 4.4,
    tongDanhGia: 87,
    tongLuotLuu: 2600,
    tuKhoa: 'tp hcm, ho chi minh, sai gon, am thuc, mua sam, cho, local',
    moTa:
        'Khu chợ nổi tiếng ở trung tâm TP.HCM, phù hợp ăn uống, mua sắm đặc sản và chụp ảnh không khí Sài Gòn.',
    trangThai: 'active',
    khoangCachHienThi: '800 m',
    thoiGianUocTinhHienThi: '5 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 10,
        maDiaDiem: 4,
        loaiMedia: 'image',
        duongDan: 'assets/images/anh2.jpg',
      ),
      MediaDiaDiemModel(
        maMedia: 11,
        maDiaDiem: 4,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac2.jpg',
      ),
    ],
  ),
  DiaDiemModel(
    maDiaDiem: 5,
    maLoai: 5,
    tenDiaDiem: 'Nhà thờ Đức Bà',
    tinhThanh: 'TP.HCM',
    quanHuyen: 'Quận 1',
    diaChi: 'Công xã Paris, Bến Nghé, Quận 1, TP.HCM',
    viDo: 10.779800,
    kinhDo: 106.699000,
    gioMoCua: '08:00 - 17:00',
    mucGia: 0,
    diemTrungBinh: 4.3,
    tongDanhGia: 65,
    tongLuotLuu: 1900,
    tuKhoa: 'tp hcm, ho chi minh, sai gon, nha tho duc ba, checkin, van hoa, kien truc',
    moTa:
        'Công trình kiến trúc nổi bật ở trung tâm Sài Gòn, thường được chọn để chụp ảnh, đi dạo và ghé các quán cà phê gần đó.',
    trangThai: 'active',
    khoangCachHienThi: '1,2 km',
    thoiGianUocTinhHienThi: '7 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 12,
        maDiaDiem: 5,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac3.jpg',
      ),
    ],
  ),
  DiaDiemModel(
    maDiaDiem: 6,
    maLoai: 5,
    tenDiaDiem: 'Hồ Hoàn Kiếm',
    tinhThanh: 'Hà Nội',
    quanHuyen: 'Hoàn Kiếm',
    diaChi: 'Trung tâm quận Hoàn Kiếm, Hà Nội',
    viDo: 21.028700,
    kinhDo: 105.852100,
    gioMoCua: 'Cả ngày',
    mucGia: 0,
    diemTrungBinh: 4.7,
    tongDanhGia: 120,
    tongLuotLuu: 4200,
    tuKhoa: 'ha noi, ho guom, ho hoan kiem, pho co, checkin, di dao, hot',
    moTa:
        'Địa điểm biểu tượng của Hà Nội, phù hợp đi bộ, chụp ảnh, tham quan phố cổ và thưởng thức ẩm thực xung quanh.',
    trangThai: 'active',
    khoangCachHienThi: '1 km',
    thoiGianUocTinhHienThi: '6 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 13,
        maDiaDiem: 6,
        loaiMedia: 'image',
        duongDan: 'assets/images/anh3.jpg',
      ),
    ],
  ),
  DiaDiemModel(
    maDiaDiem: 7,
    maLoai: 3,
    tenDiaDiem: 'Văn Miếu Quốc Tử Giám',
    tinhThanh: 'Hà Nội',
    quanHuyen: 'Đống Đa',
    diaChi: '58 Quốc Tử Giám, Đống Đa, Hà Nội',
    viDo: 21.028000,
    kinhDo: 105.835500,
    gioMoCua: '08:00 - 17:00',
    mucGia: 70000,
    diemTrungBinh: 4.6,
    tongDanhGia: 74,
    tongLuotLuu: 1700,
    tuKhoa: 'ha noi, van mieu, quoc tu giam, van hoa, lich su, di tich',
    moTa:
        'Di tích văn hóa - lịch sử nổi tiếng tại Hà Nội, phù hợp tham quan, tìm hiểu truyền thống học tập và chụp ảnh cổ kính.',
    trangThai: 'active',
    khoangCachHienThi: '2,5 km',
    thoiGianUocTinhHienThi: '12 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 14,
        maDiaDiem: 7,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac1.jpg',
      ),
    ],
  ),
  DiaDiemModel(
    maDiaDiem: 8,
    maLoai: 3,
    tenDiaDiem: 'Đại Nội Huế',
    tinhThanh: 'Huế',
    quanHuyen: 'TP Huế',
    diaChi: 'Phú Hậu, TP Huế, Thừa Thiên Huế',
    viDo: 16.469200,
    kinhDo: 107.577700,
    gioMoCua: '07:00 - 17:30',
    mucGia: 200000,
    diemTrungBinh: 4.8,
    tongDanhGia: 96,
    tongLuotLuu: 3100,
    tuKhoa: 'hue, dai noi hue, co do, van hoa, lich su, di tich',
    moTa:
        'Quần thể di tích lịch sử nổi tiếng tại Huế, phù hợp tham quan văn hóa, chụp ảnh cổ phục và tìm hiểu kiến trúc cung đình.',
    trangThai: 'active',
    khoangCachHienThi: '4 km',
    thoiGianUocTinhHienThi: '14 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 15,
        maDiaDiem: 8,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac4.jpg',
      ),
    ],
  ),
  DiaDiemModel(
    maDiaDiem: 9,
    maLoai: 2,
    tenDiaDiem: 'Langbiang',
    tinhThanh: 'Lâm Đồng',
    quanHuyen: 'Lạc Dương',
    diaChi: 'Thị trấn Lạc Dương, Lâm Đồng',
    viDo: 12.049900,
    kinhDo: 108.438400,
    gioMoCua: '07:00 - 17:00',
    mucGia: 50000,
    diemTrungBinh: 4.5,
    tongDanhGia: 58,
    tongLuotLuu: 1600,
    tuKhoa: 'da lat, lam dong, langbiang, nui rung, thien nhien, trekking',
    moTa:
        'Địa điểm thiên nhiên nổi tiếng gần Đà Lạt, phù hợp ngắm cảnh, trekking nhẹ, chụp ảnh và đi cùng nhóm bạn.',
    trangThai: 'active',
    khoangCachHienThi: '12 km',
    thoiGianUocTinhHienThi: '35 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 16,
        maDiaDiem: 9,
        loaiMedia: 'image',
        duongDan: 'assets/images/khoanhkhac5.jpg',
      ),
    ],
  ),
  DiaDiemModel(
    maDiaDiem: 10,
    maLoai: 4,
    tenDiaDiem: 'Chợ đêm Đà Lạt',
    tinhThanh: 'Lâm Đồng',
    quanHuyen: 'Đà Lạt',
    diaChi: 'Nguyễn Thị Minh Khai, Phường 1, Đà Lạt',
    viDo: 11.940400,
    kinhDo: 108.437600,
    gioMoCua: '18:00 - 23:30',
    mucGia: 100000,
    diemTrungBinh: 4.2,
    tongDanhGia: 80,
    tongLuotLuu: 2400,
    tuKhoa: 'da lat, lam dong, cho dem, am thuc, mua sam, local',
    moTa:
        'Khu chợ đêm đông vui tại trung tâm Đà Lạt, phù hợp ăn uống, mua đồ lưu niệm và trải nghiệm không khí địa phương.',
    trangThai: 'active',
    khoangCachHienThi: '1,5 km',
    thoiGianUocTinhHienThi: '8 phút di chuyển',
    media: [
      MediaDiaDiemModel(
        maMedia: 17,
        maDiaDiem: 10,
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
      tenNguoiDung: 'Thành',
    ),
    DanhGiaDiaDiemModel(
      maDanhGia: 3,
      idNguoiDung: 3,
      maDiaDiem: 1,
      soSao: 5,
      noiDung: 'Giá cả ổn, cuối tuần hơi đông nhưng vẫn đáng đi.',
      trangThai: 'active',
      ngayTao: DateTime(2026, 5, 22),
      tenNguoiDung: 'Xuân Thu',
    ),
    DanhGiaDiaDiemModel(
      maDanhGia: 4,
      idNguoiDung: 4,
      maDiaDiem: 4,
      soSao: 4,
      noiDung: 'Nhiều món ăn, đi buổi chiều tối là hợp nhất.',
      trangThai: 'active',
      ngayTao: DateTime(2026, 5, 23),
      tenNguoiDung: 'Minh Anh',
    ),
    DanhGiaDiaDiemModel(
      maDanhGia: 5,
      idNguoiDung: 5,
      maDiaDiem: 6,
      soSao: 5,
      noiDung: 'Không khí dễ chịu, gần phố cổ nên đi bộ rất tiện.',
      trangThai: 'active',
      ngayTao: DateTime(2026, 5, 24),
      tenNguoiDung: 'Gia Huy',
    ),
    DanhGiaDiaDiemModel(
      maDanhGia: 6,
      idNguoiDung: 6,
      maDiaDiem: 8,
      soSao: 5,
      noiDung: 'Rất hợp để tham quan văn hóa, nên đi buổi sáng cho mát.',
      trangThai: 'active',
      ngayTao: DateTime(2026, 5, 24),
      tenNguoiDung: 'Hoàng Phúc',
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
