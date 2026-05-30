class MediaDiaDiemModel {
  final int maMedia;
  final int maDiaDiem;
  final String loaiMedia; // image / video
  final String duongDan;
  final String? chuThich;
  final DateTime? ngayTao;

  const MediaDiaDiemModel({
    required this.maMedia,
    required this.maDiaDiem,
    required this.loaiMedia,
    required this.duongDan,
    this.chuThich,
    this.ngayTao,
  });

  factory MediaDiaDiemModel.fromJson(Map<String, dynamic> json) {
    return MediaDiaDiemModel(
      maMedia: json['maMedia'] ?? json['MaMedia'] ?? 0,
      maDiaDiem: json['maDiaDiem'] ?? json['MaDiaDiem'] ?? 0,
      loaiMedia: json['loaiMedia'] ?? json['LoaiMedia'] ?? 'image',
      duongDan: json['duongDan'] ?? json['DuongDan'] ?? '',
      chuThich: json['chuThich'] ?? json['ChuThich'],
      ngayTao: _parseDate(json['ngayTao'] ?? json['NgayTao']),
    );
  }
}

class DiaDiemModel {
  final int maDiaDiem;
  final int maLoai;

  final String tenDiaDiem;
  final String tinhThanh;
  final String? quanHuyen;
  final String? diaChi;

  final double viDo;
  final double kinhDo;

  final String? gioMoCua;
  final double? mucGia;

  final double diemTrungBinh;
  final int tongDanhGia;
  final int tongLuotLuu;

  final String? tuKhoa;
  final String? moTa;
  final String trangThai;
  final DateTime? ngayTao;

  final List<MediaDiaDiemModel> media;

  // Không có trong bảng DiaDiem.
  // Đây là dữ liệu app/backend tự tính từ GPS hiện tại của user.
  final String? khoangCachHienThi;
  final String? thoiGianUocTinhHienThi;

  const DiaDiemModel({
    required this.maDiaDiem,
    required this.maLoai,
    required this.tenDiaDiem,
    required this.tinhThanh,
    this.quanHuyen,
    this.diaChi,
    required this.viDo,
    required this.kinhDo,
    this.gioMoCua,
    this.mucGia,
    required this.diemTrungBinh,
    required this.tongDanhGia,
    required this.tongLuotLuu,
    this.tuKhoa,
    this.moTa,
    required this.trangThai,
    this.ngayTao,
    this.media = const [],
    this.khoangCachHienThi,
    this.thoiGianUocTinhHienThi,
  });

  factory DiaDiemModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'] ?? json['MediaDiaDiem'] ?? [];

    return DiaDiemModel(
      maDiaDiem: json['maDiaDiem'] ?? json['MaDiaDiem'] ?? 0,
      maLoai: json['maLoai'] ?? json['MaLoai'] ?? 0,
      tenDiaDiem: json['tenDiaDiem'] ?? json['TenDiaDiem'] ?? '',
      tinhThanh: json['tinhThanh'] ?? json['TinhThanh'] ?? '',
      quanHuyen: json['quanHuyen'] ?? json['QuanHuyen'],
      diaChi: json['diaChi'] ?? json['DiaChi'],
      viDo: _toDouble(json['viDo'] ?? json['ViDo']),
      kinhDo: _toDouble(json['kinhDo'] ?? json['KinhDo']),
      gioMoCua: json['gioMoCua'] ?? json['GioMoCua'],
      mucGia: _toNullableDouble(json['mucGia'] ?? json['MucGia']),
      diemTrungBinh: _toDouble(json['diemTrungBinh'] ?? json['DiemTrungBinh']),
      tongDanhGia: json['tongDanhGia'] ?? json['TongDanhGia'] ?? 0,
      tongLuotLuu: json['tongLuotLuu'] ?? json['TongLuotLuu'] ?? 0,
      tuKhoa: json['tuKhoa'] ?? json['TuKhoa'],
      moTa: json['moTa'] ?? json['MoTa'],
      trangThai: json['trangThai'] ?? json['TrangThai'] ?? 'active',
      ngayTao: _parseDate(json['ngayTao'] ?? json['NgayTao']),
      media: rawMedia is List
          ? rawMedia.map((e) => MediaDiaDiemModel.fromJson(e)).toList()
          : [],
      khoangCachHienThi: json['khoangCachHienThi'],
      thoiGianUocTinhHienThi: json['thoiGianUocTinhHienThi'],
    );
  }

  // Getter phụ để UI dễ gọi.
  int get id => maDiaDiem;

  String get ten => tenDiaDiem;

  double get lat => viDo;

  double get lng => kinhDo;

  double get diemDanhGia => diemTrungBinh;

  int get soLuotDanhGia => tongDanhGia;

  String get diaChiHienThi => diaChi ?? 'Đang cập nhật địa chỉ';

  String get moTaHienThi => moTa ?? 'Đang cập nhật mô tả địa điểm';

  String get khoangCach => khoangCachHienThi ?? 'Chưa xác định';

  String get thoiGianUocTinh => thoiGianUocTinhHienThi ?? 'Chưa xác định';

  String get soLuotThich {
    if (tongLuotLuu >= 1000) {
      final value = tongLuotLuu / 1000;
      return '${value.toStringAsFixed(1).replaceAll('.', ',')}k';
    }

    return tongLuotLuu.toString();
  }

  String get giaTrungBinh {
    if (mucGia == null || mucGia == 0) {
      return 'Miễn phí';
    }

    return '${mucGia!.toStringAsFixed(0)} VNĐ';
  }

  List<String> get hinhAnh {
    final images = media
        .where((item) => item.loaiMedia == 'image')
        .map((item) => item.duongDan)
        .where((path) => path.isNotEmpty)
        .toList();

    if (images.isEmpty) {
      return ['assets/images/anh1.jpg'];
    }

    return images;
  }
}

class MediaDanhGiaModel {
  final int maMedia;
  final int maDanhGia;
  final String loaiMedia; // image / video
  final String duongDan;
  final String? chuThich;
  final DateTime? ngayTao;

  const MediaDanhGiaModel({
    required this.maMedia,
    required this.maDanhGia,
    required this.loaiMedia,
    required this.duongDan,
    this.chuThich,
    this.ngayTao,
  });

  factory MediaDanhGiaModel.fromJson(Map<String, dynamic> json) {
    return MediaDanhGiaModel(
      maMedia: json['maMedia'] ?? json['MaMedia'] ?? 0,
      maDanhGia: json['maDanhGia'] ?? json['MaDanhGia'] ?? 0,
      loaiMedia: json['loaiMedia'] ?? json['LoaiMedia'] ?? 'image',
      duongDan: json['duongDan'] ?? json['DuongDan'] ?? '',
      chuThich: json['chuThich'] ?? json['ChuThich'],
      ngayTao: _parseDate(json['ngayTao'] ?? json['NgayTao']),
    );
  }
}

class DanhGiaDiaDiemModel {
  final int maDanhGia;
  final int idNguoiDung;
  final int maDiaDiem;

  final int soSao;
  final String? noiDung;

  final String trangThai;
  final DateTime? ngayTao;
  final DateTime? ngayCapNhat;

  final List<MediaDanhGiaModel> media;

  // Không nằm trực tiếp trong bảng DanhGiaDiaDiem.
  // Sau này backend join từ NguoiDung.BietDanh rồi trả về.
  final String tenNguoiDung;

  const DanhGiaDiaDiemModel({
    required this.maDanhGia,
    required this.idNguoiDung,
    required this.maDiaDiem,
    required this.soSao,
    this.noiDung,
    required this.trangThai,
    this.ngayTao,
    this.ngayCapNhat,
    this.media = const [],
    this.tenNguoiDung = 'Người dùng',
  });

  factory DanhGiaDiaDiemModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'] ?? json['MediaDanhGia'] ?? [];

    return DanhGiaDiaDiemModel(
      maDanhGia: json['maDanhGia'] ?? json['MaDanhGia'] ?? 0,
      idNguoiDung: json['idNguoiDung'] ?? json['ID'] ?? 0,
      maDiaDiem: json['maDiaDiem'] ?? json['MaDiaDiem'] ?? 0,
      soSao: json['soSao'] ?? json['SoSao'] ?? 1,
      noiDung: json['noiDung'] ?? json['NoiDung'],
      trangThai: json['trangThai'] ?? json['TrangThai'] ?? 'active',
      ngayTao: _parseDate(json['ngayTao'] ?? json['NgayTao']),
      ngayCapNhat: _parseDate(json['ngayCapNhat'] ?? json['NgayCapNhat']),
      media: rawMedia is List
          ? rawMedia.map((e) => MediaDanhGiaModel.fromJson(e)).toList()
          : [],
      tenNguoiDung:
          json['tenNguoiDung'] ??
          json['BietDanh'] ??
          json['TenNguoiDung'] ??
          'Người dùng',
    );
  }

  int get id => maDanhGia;

  int get diaDiemId => maDiaDiem;

  double get diem => soSao.toDouble();

  String get noiDungHienThi => noiDung ?? '';

  String get ngayThang {
    if (ngayTao == null) {
      return 'Ngày tháng';
    }

    return '${ngayTao!.day}/${ngayTao!.month}/${ngayTao!.year}';
  }

  List<String> get hinhAnh {
    return media
        .where((item) => item.loaiMedia == 'image')
        .map((item) => item.duongDan)
        .where((path) => path.isNotEmpty)
        .toList();
  }
}

class TaoDanhGiaDiaDiemRequest {
  final int maDiaDiem;
  final int soSao;
  final String noiDung;
  final List<String> mediaUrls;

  const TaoDanhGiaDiaDiemRequest({
    required this.maDiaDiem,
    required this.soSao,
    required this.noiDung,
    this.mediaUrls = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'maDiaDiem': maDiaDiem,
      'soSao': soSao,
      'noiDung': noiDung,
      'mediaUrls': mediaUrls,
    };
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value.toDouble();

  if (value is double) return value;

  return double.tryParse(value.toString()) ?? 0;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;

  if (value is int) return value.toDouble();

  if (value is double) return value;

  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}
