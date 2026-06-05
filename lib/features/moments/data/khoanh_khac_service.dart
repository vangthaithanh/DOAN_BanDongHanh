import 'package:supabase_flutter/supabase_flutter.dart';
import 'model/khoanh_khac_mau.dart';

class KhoanhKhacService {
  final _client = Supabase.instance.client;

  Future<List<String>> _getMutualFriendIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    try {
      final following = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', user.id)
          .eq('status', 'active');
      final followingIds = (following as List)
          .map((e) => e['following_id'].toString())
          .toSet();

      final followers = await _client
          .from('follows')
          .select('follower_id')
          .eq('following_id', user.id)
          .eq('status', 'active');
      final followerIds = (followers as List)
          .map((e) => e['follower_id'].toString())
          .toSet();

      return followingIds.intersection(followerIds).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final me = _client.auth.currentUser;
    if (me == null) return null;
    try {
      final res = await _client
          .from('profiles')
          .select('id, nickname, avatar_url')
          .eq('id', me.id)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getBanBe() async {
    try {
      final ids = await _getMutualFriendIds();
      if (ids.isEmpty) return [];
      final res = await _client
          .from('profiles')
          .select('id, nickname, avatar_url')
          .inFilter('id', ids)
          .order('nickname');
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<KhoanhKhacMau>> getKhoanhKhac({String? profileId}) async {
    try {
      var query = _client
          .from('moments')
          .select('id, image_url, nearby_place_name, created_at, profile_id,'
              'profiles:profile_id(nickname, avatar_url)')
          .eq('status', 'active');

      if (profileId != null) {
        query = query.eq('profile_id', profileId);
      } else {
        final friendIds = await _getMutualFriendIds();
        final me = _client.auth.currentUser?.id;
        final ids = [...friendIds, ?me];
        if (ids.isEmpty) return [];
        query = query.inFilter('profile_id', ids);
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
          avatarUrl: e['profiles']?['avatar_url']?.toString(),
          viTri: e['nearby_place_name'],
          thoiGian: e['created_at'] != null
              ? DateTime.tryParse(e['created_at'])?.toLocal()
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
