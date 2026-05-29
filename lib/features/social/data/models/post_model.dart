class PostModel {
  final int id;
  final String tenNguoiDang;
  final String thoiGian;
  final String? caption;
  final List<String> danhSachAnh;
  final String? viTri;
  final List<String> danhSachHashTag;
  final List<String> danhSachBanBeDuocTag;
  final int soLuotThich;
  final int soLuotBinhLuan;
  final bool laBaiVietCuaToi;

  const PostModel({
    required this.id,
    required this.tenNguoiDang,
    required this.thoiGian,
    this.caption,
    this.danhSachAnh = const [],
    this.viTri,
    this.danhSachHashTag = const [],
    this.danhSachBanBeDuocTag = const [],
    this.soLuotThich = 0,
    this.soLuotBinhLuan = 0,
    this.laBaiVietCuaToi = false,
  });

  PostModel copyWith({
    int? id,
    String? tenNguoiDang,
    String? thoiGian,
    String? caption,
    List<String>? danhSachAnh,
    String? viTri,
    List<String>? danhSachHashTag,
    List<String>? danhSachBanBeDuocTag,
    int? soLuotThich,
    int? soLuotBinhLuan,
    bool? laBaiVietCuaToi,
  }) {
    return PostModel(
      id: id ?? this.id,
      tenNguoiDang: tenNguoiDang ?? this.tenNguoiDang,
      thoiGian: thoiGian ?? this.thoiGian,
      caption: caption ?? this.caption,
      danhSachAnh: danhSachAnh ?? this.danhSachAnh,
      viTri: viTri ?? this.viTri,
      danhSachHashTag: danhSachHashTag ?? this.danhSachHashTag,
      danhSachBanBeDuocTag:
      danhSachBanBeDuocTag ?? this.danhSachBanBeDuocTag,
      soLuotThich: soLuotThich ?? this.soLuotThich,
      soLuotBinhLuan: soLuotBinhLuan ?? this.soLuotBinhLuan,
      laBaiVietCuaToi: laBaiVietCuaToi ?? this.laBaiVietCuaToi,
    );
  }
}