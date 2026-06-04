import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/khoanh_khac_mau.dart';

class KhoanhKhacService {
  final _client = Supabase.instance.client;

  Future<List<KhoanhKhacMau>> getKhoanhKhac({String? profileId}) async {
    try {
      var query = _client
          .from('moments')
          .select('''
            id,
            image_url,
            nearby_place_name,
            created_at,
            profile_id,
            profiles!moments_profile_id_fkey (
              nickname
            )
          ''');
      
      if (profileId != null) {
        query = query.eq('profile_id', profileId);
      }

      final res = await query.order('created_at', ascending: false);
      final data = res as List;

      return data.map((e) {
        final rawId = e['id'];
        final int id = rawId is int ? rawId : (int.tryParse(rawId?.toString() ?? '0') ?? 0);

        return KhoanhKhacMau(
          id: id,
          duongDanAnh: e['image_url'] ?? '',
          tenNguoiDang: e['profiles']?['nickname'] ?? 'Người dùng',
          profileId: e['profile_id']?.toString(),
          viTri: e['nearby_place_name'],
          thoiGian: e['created_at'] != null
              ? DateTime.tryParse(e['created_at'])
              : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Lỗi tải dữ liệu moments: $e');
    }
  }

  // Trả về dữ liệu thô dạng Map để không phụ thuộc vào class MyProfile đã xóa
  Future<List<Map<String, dynamic>>> getTatCaProfiles() async {
    try {
      final res = await _client
          .from('profiles')
          .select('id, nickname, avatar_url')
          .order('nickname', ascending: true);
      
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      throw Exception('Lỗi tải danh sách người dùng: $e');
    }
  }

  Future<void> xoaKhoanhKhac(int id) async {
    try {
      await _client.from('moments').delete().eq('id', id);
    } catch (e) {
      throw Exception('Xóa thất bại: $e');
    }
  }
}
