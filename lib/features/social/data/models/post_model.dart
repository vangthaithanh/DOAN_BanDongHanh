class PostModel {
  final int id;
  final String? authorId; // ID của người đăng để vào trang cá nhân
  final String tenNguoiDang;
  final String? anhDaiDienNguoiDang;
  final String thoiGian;
  final String? caption;
  final List<String> danhSachAnh;
  final String? viTri;
  final List<String> danhSachHashTag;
  final List<String> danhSachBanBeDuocTag;
  final int soLuotThich;
  final int soLuotBinhLuan;
  final bool daThich;
  final bool laBaiVietCuaToi;
  final DateTime? createdAt;
  final String? visibility;

  // NOTE SỬA LƯU TRỮ:
  // active   -> hiện bình thường
  // archived -> nằm trong kho lưu trữ
  // deleted  -> đã xoá mềm
  final String? status;
  final bool isArchived;

  const PostModel({
    required this.id,
    this.authorId,
    required this.tenNguoiDang,
    this.anhDaiDienNguoiDang,
    required this.thoiGian,
    this.caption,
    this.danhSachAnh = const [],
    this.viTri,
    this.danhSachHashTag = const [],
    this.danhSachBanBeDuocTag = const [],
    this.soLuotThich = 0,
    this.soLuotBinhLuan = 0,
    this.daThich = false,
    this.laBaiVietCuaToi = false,
    this.createdAt,
    this.visibility,
    this.status,
    this.isArchived = false,
  });

  PostModel copyWith({
    int? id,
    String? authorId,
    String? tenNguoiDang,
    String? anhDaiDienNguoiDang,
    String? thoiGian,
    String? caption,
    List<String>? danhSachAnh,
    String? viTri,
    List<String>? danhSachHashTag,
    List<String>? danhSachBanBeDuocTag,
    int? soLuotThich,
    int? soLuotBinhLuan,
    bool? daThich,
    bool? laBaiVietCuaToi,
    DateTime? createdAt,
    String? visibility,
    String? status,
    bool? isArchived,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      tenNguoiDang: tenNguoiDang ?? this.tenNguoiDang,
      anhDaiDienNguoiDang: anhDaiDienNguoiDang ?? this.anhDaiDienNguoiDang,
      thoiGian: thoiGian ?? this.thoiGian,
      caption: caption ?? this.caption,
      danhSachAnh: danhSachAnh ?? this.danhSachAnh,
      viTri: viTri ?? this.viTri,
      danhSachHashTag: danhSachHashTag ?? this.danhSachHashTag,
      danhSachBanBeDuocTag: danhSachBanBeDuocTag ?? this.danhSachBanBeDuocTag,
      soLuotThich: soLuotThich ?? this.soLuotThich,
      soLuotBinhLuan: soLuotBinhLuan ?? this.soLuotBinhLuan,
      daThich: daThich ?? this.daThich,
      laBaiVietCuaToi: laBaiVietCuaToi ?? this.laBaiVietCuaToi,
      createdAt: createdAt ?? this.createdAt,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
