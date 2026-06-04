class KhoanhKhacMau {
  final int id;
  final String duongDanAnh;
  final String tenNguoiDang;
  final String? profileId; // Thêm profileId để hỗ trợ lọc
  final String? viTri;
  final DateTime? thoiGian;

  const KhoanhKhacMau({
    required this.id,
    required this.duongDanAnh,
    required this.tenNguoiDang,
    this.profileId,
    this.viTri,
    this.thoiGian,
  });

  factory KhoanhKhacMau.fromJson(Map<String, dynamic> json) {
    return KhoanhKhacMau(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      duongDanAnh: json['image_url'] ?? '',
      tenNguoiDang: json['profiles']?['nickname'] ?? json['username'] ?? 'Người dùng',
      profileId: json['profile_id']?.toString(),
      viTri: json['nearby_place_name'],
      thoiGian: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
