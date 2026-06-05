class KhoanhKhacMau {
  final int id;
  final String duongDanAnh;
  final String tenNguoiDang;
  final String? profileId;
  final String? avatarUrl;
  final String? viTri;
  final DateTime? thoiGian;

  const KhoanhKhacMau({
    required this.id,
    required this.duongDanAnh,
    required this.tenNguoiDang,
    this.profileId,
    this.avatarUrl,
    this.viTri,
    this.thoiGian,
  });

  factory KhoanhKhacMau.fromJson(Map<String, dynamic> json) {
    return KhoanhKhacMau(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      duongDanAnh: json['image_url'] ?? '',
      tenNguoiDang: json['profiles']?['nickname'] ?? json['username'] ?? 'Người dùng',
      profileId: json['profile_id']?.toString(),
      avatarUrl: json['profiles']?['avatar_url']?.toString(),
      viTri: json['nearby_place_name'],
      thoiGian: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
