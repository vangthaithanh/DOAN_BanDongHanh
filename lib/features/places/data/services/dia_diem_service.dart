import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dia_diem_model.dart';

class DiaDiemService {
  static const double _gocLatHcm = 10.776889;
  static const double _gocLngHcm = 106.700806;

  final SupabaseClient _client = Supabase.instance.client;

  Future<List<DiaDiemModel>> layDanhSachDiaDiem() async {
    final userId = _client.auth.currentUser?.id;
    var query = _client
        .from('places')
        .select('*, place_media(*)')
        .eq('status', 'active');

    query = userId == null
        ? query.filter('user_id', 'is', null)
        : query.or('user_id.is.null,user_id.eq.$userId');

    final data = await query
        .order('avg_rating', ascending: false)
        .order('total_saves', ascending: false);

    return List<Map<String, dynamic>>.from(
      data,
    ).map((row) => DiaDiemModel.fromJson(_mapPlaceRow(row))).toList();
  }

  Future<DiaDiemModel?> layDiaDiemTheoId(int maDiaDiem) async {
    final userId = _client.auth.currentUser?.id;
    var query = _client
        .from('places')
        .select('*, place_media(*)')
        .eq('id', maDiaDiem);

    query = userId == null
        ? query.filter('user_id', 'is', null)
        : query.or('user_id.is.null,user_id.eq.$userId');

    final data = await query.maybeSingle();

    if (data == null) return null;

    return DiaDiemModel.fromJson(_mapPlaceRow(Map<String, dynamic>.from(data)));
  }

  Future<List<DiaDiemModel>> layDiaDiemLienQuan(DiaDiemModel diaDiem) async {
    final userId = _client.auth.currentUser?.id;
    var query = _client
        .from('places')
        .select('*, place_media(*)')
        .eq('status', 'active')
        .neq('id', diaDiem.maDiaDiem)
        .or(
          'province.eq.${diaDiem.tinhThanh},category_id.eq.${diaDiem.maLoai}',
        );

    query = userId == null
        ? query.filter('user_id', 'is', null)
        : query.or('user_id.is.null,user_id.eq.$userId');

    final data = await query.order('avg_rating', ascending: false).limit(6);

    return List<Map<String, dynamic>>.from(
      data,
    ).map((row) => DiaDiemModel.fromJson(_mapPlaceRow(row))).toList();
  }

  Future<List<DanhGiaDiaDiemModel>> layDanhGiaTheoDiaDiem(
    int maDiaDiem, {
    int limit = 20,
  }) async {
    final data = await _client
        .from('place_reviews')
        .select('''
          id,
          profile_id,
          place_id,
          rating,
          content,
          status,
          created_at,
          updated_at,
          review_media (
            id,
            review_id,
            media_type,
            url,
            caption,
            created_at
          ),
          profiles:profiles!place_reviews_profile_id_fkey (
            id,
            nickname,
            full_name,
            avatar_url
          )
        ''')
        .eq('place_id', maDiaDiem)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(
      data,
    ).map((row) => DanhGiaDiaDiemModel.fromJson(_mapReviewRow(row))).toList();
  }

  // NOTE SỬA:
  // Lấy riêng đánh giá của user hiện tại.
  // Dùng để trang chi tiết biết user đã đánh giá chưa.
  Future<DanhGiaDiaDiemModel?> layDanhGiaCuaToi(int maDiaDiem) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final data = await _client
        .from('place_reviews')
        .select('''
          id,
          profile_id,
          place_id,
          rating,
          content,
          status,
          created_at,
          updated_at,
          review_media (
            id,
            review_id,
            media_type,
            url,
            caption,
            created_at
          ),
          profiles:profiles!place_reviews_profile_id_fkey (
            id,
            nickname,
            full_name,
            avatar_url
          )
        ''')
        .eq('place_id', maDiaDiem)
        .eq('profile_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (data == null) return null;

    return DanhGiaDiaDiemModel.fromJson(
      _mapReviewRow(Map<String, dynamic>.from(data)),
    );
  }

  Future<void> taoHoacCapNhatDanhGia({
    required int maDiaDiem,
    required int soSao,
    required String noiDung,
    List<XFile> hinhAnh = const [],
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để đánh giá địa điểm.');
    }

    final reviewRow = await _client
        .from('place_reviews')
        .upsert({
          'profile_id': user.id,
          'place_id': maDiaDiem,
          'rating': soSao,
          'content': noiDung,
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'profile_id,place_id')
        .select('id')
        .single();

    final reviewId = reviewRow['id'] as int;

    // NOTE SỬA:
    // Khi user đánh giá lại/chỉnh sửa đánh giá, phải xóa ảnh cũ trước.
    // Nếu không xóa, review_media cũ vẫn còn nên ảnh cũ sẽ hiện lại.
    await _xoaMediaCuCuaDanhGia(reviewId);

    // Nếu lần lưu mới không chọn ảnh thì dừng ở đây.
    // Kết quả: sao/nội dung được cập nhật, ảnh cũ bị xóa hết.
    if (hinhAnh.isEmpty) return;

    final mediaRows = <Map<String, dynamic>>[];

    for (var i = 0; i < hinhAnh.length; i++) {
      final file = hinhAnh[i];
      final bytes = await file.readAsBytes();
      final ext = _getExt(file.name.isNotEmpty ? file.name : file.path);
      final path =
          '${user.id}/review_${reviewId}_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
      final contentType = _contentTypeFromExt(ext);

      await _client.storage
          .from('review-media')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = _client.storage.from('review-media').getPublicUrl(path);

      mediaRows.add({
        'review_id': reviewId,
        'media_type': 'image',
        'url': publicUrl,
        'caption': null,
      });
    }

    if (mediaRows.isNotEmpty) {
      await _client.from('review_media').insert(mediaRows);
    }
  }

  // NOTE SỬA:
  // Xóa đánh giá của chính user hiện tại.
  // Dùng cho nút 3 chấm ở "Đánh giá của bạn" trong trang chi tiết.
  Future<void> xoaDanhGiaCuaToi(int maDiaDiem) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xóa đánh giá.');
    }

    final reviewRow = await _client
        .from('place_reviews')
        .select('id')
        .eq('place_id', maDiaDiem)
        .eq('profile_id', user.id)
        .maybeSingle();

    if (reviewRow == null) return;

    final reviewId = reviewRow['id'] as int;

    await _xoaMediaCuCuaDanhGia(reviewId);

    await _client
        .from('place_reviews')
        .delete()
        .eq('id', reviewId)
        .eq('profile_id', user.id);
  }

  Future<void> _xoaMediaCuCuaDanhGia(int reviewId) async {
    final oldMedia = await _client
        .from('review_media')
        .select('id, url')
        .eq('review_id', reviewId);

    final rows = List<Map<String, dynamic>>.from(oldMedia);

    if (rows.isEmpty) return;

    final storagePaths = rows
        .map((row) => _layStoragePathReviewMedia(row['url']?.toString() ?? ''))
        .whereType<String>()
        .where((path) => path.trim().isNotEmpty)
        .toList();

    // Xóa dòng trong DB trước để UI không còn hiện ảnh cũ.
    await _client.from('review_media').delete().eq('review_id', reviewId);

    // Xóa file trong Storage để không bị rác bộ nhớ.
    // Nếu file cũ là URL ngoài bucket hoặc policy không cho xóa thì bỏ qua,
    // vì DB đã xóa nên UI không còn hiện ảnh cũ nữa.
    if (storagePaths.isNotEmpty) {
      try {
        await _client.storage.from('review-media').remove(storagePaths);
      } catch (_) {
        // Bỏ qua lỗi xóa storage để không làm fail thao tác lưu/xóa đánh giá.
      }
    }
  }

  String? _layStoragePathReviewMedia(String url) {
    if (url.trim().isEmpty) return null;

    const markers = [
      '/storage/v1/object/public/review-media/',
      '/storage/v1/object/sign/review-media/',
      '/object/public/review-media/',
      '/object/sign/review-media/',
    ];

    for (final marker in markers) {
      final index = url.indexOf(marker);
      if (index == -1) continue;

      final rawPath = url.substring(index + marker.length).split('?').first;
      if (rawPath.trim().isEmpty) return null;

      try {
        return Uri.decodeFull(rawPath);
      } catch (_) {
        return rawPath;
      }
    }

    // Trường hợp DB lưu thẳng path dạng: user_id/file.jpg
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      try {
        return Uri.decodeFull(url);
      } catch (_) {
        return url;
      }
    }

    return null;
  }

  Map<String, dynamic> _mapPlaceRow(Map<String, dynamic> row) {
    final rawMedia = row['place_media'];
    final media = rawMedia is List ? List<dynamic>.from(rawMedia) : <dynamic>[];
    final coverImage = row['cover_image']?.toString().trim() ?? '';

    if (coverImage.isNotEmpty) {
      final alreadyIncluded = media.any((item) {
        if (item is! Map) return false;
        return item['url']?.toString() == coverImage;
      });

      if (!alreadyIncluded) {
        media.insert(0, {
          'id': 0,
          'place_id': row['id'] ?? 0,
          'media_type': 'image',
          'url': coverImage,
          'caption': null,
          'created_at': row['updated_at'] ?? row['created_at'],
        });
      }
    }
    final lat = _toDouble(row['latitude']);
    final lng = _toDouble(row['longitude']);
    final distanceKm = _tinhKhoangCachKm(_gocLatHcm, _gocLngHcm, lat, lng);

    return {
      'maDiaDiem': row['id'] ?? 0,
      'maLoai': row['category_id'] ?? 0,
      'tenDiaDiem': row['name'] ?? '',
      'tinhThanh': row['province'] ?? '',
      'quanHuyen': row['district'],
      'diaChi': row['address'],
      'viDo': lat,
      'kinhDo': lng,
      'gioMoCua': row['opening_hours'],
      'mucGia': row['price'],
      'diemTrungBinh': row['avg_rating'] ?? 0,
      'tongDanhGia': row['total_reviews'] ?? 0,
      'tongLuotLuu': row['total_saves'] ?? 0,
      'tuKhoa': row['keywords'],
      'moTa': row['description'],
      'trangThai': row['status'] ?? 'active',
      'ngayTao': row['created_at'],
      'media': media.map((item) {
        final m = Map<String, dynamic>.from(item as Map);
        return {
          'maMedia': m['id'] ?? 0,
          'maDiaDiem': m['place_id'] ?? 0,
          'loaiMedia': m['media_type'] ?? 'image',
          'duongDan': m['url'] ?? '',
          'chuThich': m['caption'],
          'ngayTao': m['created_at'],
        };
      }).toList(),
      'khoangCachHienThi': _formatDistance(distanceKm),
      'thoiGianUocTinhHienThi': _formatDuration(distanceKm),
    };
  }

  Map<String, dynamic> _mapReviewRow(Map<String, dynamic> row) {
    final rawMedia = row['review_media'];
    final media = rawMedia is List ? rawMedia : const [];
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : <String, dynamic>{};

    final fullName = profile['full_name']?.toString().trim() ?? '';
    final nickname = profile['nickname']?.toString().trim() ?? '';

    return {
      'maDanhGia': row['id'] ?? 0,
      'idNguoiDung': 0,
      'maDiaDiem': row['place_id'] ?? 0,
      'soSao': row['rating'] ?? 1,
      'noiDung': row['content'],
      'trangThai': row['status'] ?? 'active',
      'ngayTao': row['created_at'],
      'ngayCapNhat': row['updated_at'],
      'tenNguoiDung': fullName.isNotEmpty
          ? fullName
          : nickname.isNotEmpty
          ? nickname
          : 'Người dùng',
      'media': media.map((item) {
        final m = Map<String, dynamic>.from(item as Map);
        return {
          'maMedia': m['id'] ?? 0,
          'maDanhGia': m['review_id'] ?? 0,
          'loaiMedia': m['media_type'] ?? 'image',
          'duongDan': m['url'] ?? '',
          'chuThich': m['caption'],
          'ngayTao': m['created_at'],
        };
      }).toList(),
    };
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }

  double _tinhKhoangCachKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreeToRadian(lat2 - lat1);
    final dLon = _degreeToRadian(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreeToRadian(lat1)) *
            math.cos(_degreeToRadian(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreeToRadian(double degree) {
    return degree * math.pi / 180;
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }

    return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  String _formatDuration(double distanceKm) {
    const averageSpeedKmPerHour = 25.0;
    final minutes = math.max(
      1,
      (distanceKm / averageSpeedKmPerHour * 60).round(),
    );

    if (minutes < 60) {
      return '$minutes phút đi xe';
    }

    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;

    if (remainMinutes == 0) {
      return '$hours giờ đi xe';
    }

    return '$hours giờ $remainMinutes phút đi xe';
  }

  String _getExt(String path) {
    final clean = path.split('?').first;
    final index = clean.lastIndexOf('.');
    if (index == -1 || index == clean.length - 1) return 'jpg';

    final ext = clean.substring(index + 1).toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) return ext;
    return 'jpg';
  }

  String _contentTypeFromExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
