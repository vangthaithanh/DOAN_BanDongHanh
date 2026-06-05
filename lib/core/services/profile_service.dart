import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/social/data/models/post_model.dart';

/// NOTE SỬA:
/// Service này dùng cho trang cá nhân.
/// Query khớp RLS/database hiện tại:
/// follows: follower_id, following_id
/// friends: không dùng để đếm bạn bè nữa
/// posts: profile_id
/// itineraries: profile_id
/// itinerary_items: itinerary_id
class MyProfile {
  final String id;
  final String nickname;
  final String email;
  final String fullName;
  final String avatarUrl;
  final String bio;
  final String facebookUrl;

  const MyProfile({
    required this.id,
    required this.nickname,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.bio,
    required this.facebookUrl,
  });

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    if (nickname.trim().isNotEmpty) {
      return nickname.trim();
    }

    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'Người dùng';
  }

  factory MyProfile.fromMap(Map<String, dynamic> map) {
    return MyProfile(
      id: map['id']?.toString() ?? '',
      nickname: map['nickname']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      avatarUrl: map['avatar_url']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
      facebookUrl: map['facebook_url']?.toString() ?? '',
    );
  }
}

class ProfilePlanItemData {
  final String id;
  final int placeId;
  final String title;
  final String province;
  final String timeText;
  final String dayText;
  final String hourText;
  final String actionText;
  final bool isActive;
  final bool canShowAction;
  final String status;
  final bool gpsConfirmed;
  final String? imageUrl;
  final DateTime? plannedTime;

  const ProfilePlanItemData({
    required this.id,
    required this.placeId,
    required this.title,
    required this.province,
    required this.timeText,
    required this.dayText,
    required this.hourText,
    required this.actionText,
    required this.isActive,
    required this.canShowAction,
    required this.status,
    required this.gpsConfirmed,
    this.imageUrl,
    required this.plannedTime,
  });
}

class ProfilePlanGroupData {
  final String id;
  final String name;
  final String routeText;
  final bool pinned;
  final List<ProfilePlanItemData> items;

  const ProfilePlanGroupData({
    required this.id,
    required this.name,
    required this.routeText,
    required this.pinned,
    required this.items,
  });
}

class ProfilePageData {
  final MyProfile profile;
  final int followerCount;
  final int friendCount;
  final int postCount;
  final List<ProfilePlanGroupData> plans;
  final List<PostModel> posts;
  final bool isMe;
  final bool isFollowing;

  const ProfilePageData({
    required this.profile,
    required this.followerCount,
    required this.friendCount,
    required this.postCount,
    required this.plans,
    required this.posts,
    this.isMe = false,
    this.isFollowing = false,
  });
}

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get _currentUser => _client.auth.currentUser;

  Future<ProfilePageData> loadMine() async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }
    return loadProfile(user.id);
  }

  Future<ProfilePageData> loadProfile(String profileId) async {
    final currentUserId = _client.auth.currentUser?.id;

    final profileMap = await _client
        .from('profiles')
        .select('id, nickname, email, full_name, avatar_url, bio, facebook_url')
        .eq('id', profileId)
        .maybeSingle();

    if (profileMap == null) {
      throw Exception('Không tìm thấy hồ sơ người dùng');
    }

    final profile = MyProfile.fromMap(profileMap);

    final followerCount = await _countFollowers(profileId);
    final friendCount = await _countFriends(profileId);
    final postCount = await _countPosts(profileId);
    final plans = await _loadPlans(profileId);

    bool isFollowing = false;
    if (currentUserId != null && currentUserId != profileId) {
      isFollowing = await _checkIsFollowing(currentUserId, profileId);
    }

    // Truyền isFollowing: người xem đang follow profile owner = là follower của họ
    final posts = await _loadUserPosts(profileId, profile, isFollowing);

    return ProfilePageData(
      profile: profile,
      followerCount: followerCount,
      friendCount: friendCount,
      postCount: postCount,
      plans: plans,
      posts: posts,
      isMe: profileId == currentUserId,
      isFollowing: isFollowing,
    );
  }

  Future<bool> _checkIsFollowing(String followerId, String followingId) async {
    try {
      final row = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .eq('status', 'active')
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleFollow(String targetProfileId) async {
    final user = _currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');
    if (user.id == targetProfileId) return;

    final isFollowing = await _checkIsFollowing(user.id, targetProfileId);

    if (isFollowing) {
      // Unfollow: Xóa hoặc cập nhật status
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetProfileId);
    } else {
      // Follow: Thêm mới
      await _client.from('follows').insert({
        'follower_id': user.id,
        'following_id': targetProfileId,
        'status': 'active',
      });
    }
  }

  Future<void> updateProfile({
    required String nickname,
    required String fullName,
    required String bio,
    required String facebookUrl,
  }) async {
    final user = _currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final cleanNickname = nickname.trim();

    if (cleanNickname.length < 3) {
      throw Exception('Biệt danh tối thiểu 3 ký tự');
    }

    try {
      final isTaken = await _client.rpc(
        'is_nickname_taken',
        params: {'p_nickname': cleanNickname},
      );

      if (isTaken == true) {
        final currentProfile = await _client
            .from('profiles')
            .select('nickname')
            .eq('id', user.id)
            .maybeSingle();

        final currentNickname =
            currentProfile?['nickname']?.toString().trim().toLowerCase() ?? '';

        if (currentNickname != cleanNickname.toLowerCase()) {
          throw Exception('Biệt danh đã tồn tại');
        }
      }
    } catch (e) {
      if (e.toString().contains('Biệt danh đã tồn tại')) {
        rethrow;
      }
    }

    await _client
        .from('profiles')
        .update({
          'nickname': cleanNickname,
          'full_name': fullName.trim(),
          'bio': bio.trim(),
          'facebook_url': facebookUrl.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  Future<int> _countFollowers(String userId) async {
    try {
      final rows = await _client
          .from('follows')
          .select('id')
          .eq('following_id', userId)
          .eq('status', 'active');

      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// NOTE SỬA:
  /// Bạn bè = 2 người theo dõi nhau trong bảng follows.
  ///
  /// Ví dụ:
  /// A theo dõi B: follows.follower_id = A, follows.following_id = B
  /// B theo dõi A: follows.follower_id = B, follows.following_id = A
  ///
  /// Khi có đủ 2 chiều active thì tính là 1 bạn bè.
  Future<int> _countFriends(String userId) async {
    try {
      final followingRows = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId)
          .eq('status', 'active')
          .neq('following_id', userId);

      final followingIds = (followingRows as List)
          .map((row) {
            final map = row as Map<String, dynamic>;
            return map['following_id']?.toString() ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (followingIds.isEmpty) {
        return 0;
      }

      final mutualRows = await _client
          .from('follows')
          .select('follower_id')
          .inFilter('follower_id', followingIds)
          .eq('following_id', userId)
          .eq('status', 'active');

      final mutualIds = (mutualRows as List)
          .map((row) {
            final map = row as Map<String, dynamic>;
            return map['follower_id']?.toString() ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      return mutualIds.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countPosts(String userId) async {
    try {
      final rows = await _client
          .from('posts')
          .select('id')
          .eq('profile_id', userId)
          .eq('status', 'active');

      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<ProfilePlanGroupData>> _loadPlans(String userId) async {
    try {
      final planRows = await _client
          .from('itineraries')
          .select('id, name, description, pinned, status, created_at')
          .eq('profile_id', userId)
          .order('pinned', ascending: false)
          .order('created_at', ascending: false)
          .limit(10);

      final plans = <ProfilePlanGroupData>[];

      for (final rawPlan in planRows as List) {
        final plan = rawPlan as Map;
        final planId = plan['id']?.toString() ?? '';
        final pinned = plan['pinned'] == true;

        final items = await _loadPlanItems(
          itineraryId: planId,
          pinned: pinned,
        );

        plans.add(
          ProfilePlanGroupData(
            id: planId,
            name: _firstText([plan['name']], fallback: 'Plan'),
            routeText: items.isEmpty
                ? _firstText([plan['description']], fallback: 'Chưa có tuyến')
                : items.take(3).map((item) => item.title).join(' - '),
            pinned: pinned,
            items: items,
          ),
        );
      }

      return plans;
    } catch (_) {
      return [];
    }
  }

  Future<List<ProfilePlanItemData>> _loadPlanItems({
    required String itineraryId,
    required bool pinned,
  }) async {
    if (itineraryId.isEmpty) {
      return [];
    }

    try {
      final itemRows = await _client
          .from('itinerary_items')
          .select('''
          id,
          place_id,
          order_no,
          planned_time,
          status,
          gps_confirmed,
          places (
            id,
            name,
            province,
            district,
            address,
            place_media (
              id,
              media_type,
              url
            )
          )
        ''')
          .eq('itinerary_id', itineraryId)
          .order('planned_time', ascending: true)
          .order('order_no', ascending: true)
          .limit(30);

      final items = <ProfilePlanItemData>[];

      for (final rawItem in itemRows as List) {
        final item = rawItem as Map;
        final place = item['places'] is Map ? item['places'] as Map : {};
        final status = item['status']?.toString() ?? 'planned';
        final gpsConfirmed = item['gps_confirmed'] == true;
        final plannedTime = DateTime.tryParse(
          item['planned_time']?.toString() ?? '',
        )?.toLocal();

        items.add(
          ProfilePlanItemData(
            id: item['id']?.toString() ?? '',
            placeId: _asInt(item['place_id']),
            title: _firstText([place['name']], fallback: 'Địa điểm'),
            province: _firstText(
              [place['province'], place['district'], place['address']],
              fallback: 'Tỉnh thành',
            ),
            timeText: _formatPlanTime(plannedTime),
            dayText: _formatPlanDay(plannedTime),
            hourText: _formatPlanHour(plannedTime),
            actionText: _planActionText(
              pinned: pinned,
              status: status,
              gpsConfirmed: gpsConfirmed,
            ),
            isActive: _isActiveItem(status) || gpsConfirmed,
            canShowAction: pinned,
            status: status,
            gpsConfirmed: gpsConfirmed,
            plannedTime: plannedTime,
            imageUrl: _firstPlaceImage(place['place_media']),
          ),
        );
      }

      items.sort((a, b) {
        final aTime = a.plannedTime;
        final bTime = b.plannedTime;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return aTime.compareTo(bTime);
      });

      return items;

      return items;
    } catch (_) {
      return [];
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String? _firstPlaceImage(dynamic rawMedia) {
    if (rawMedia is! List || rawMedia.isEmpty) return null;

    for (final item in rawMedia) {
      if (item is! Map) continue;

      final type = item['media_type']?.toString() ?? 'image';
      final url = item['url']?.toString() ?? '';

      if (type == 'image' && url.trim().isNotEmpty) {
        return url;
      }
    }

    return null;
  }

  String _formatPlanDay(DateTime? dateTime) {
    if (dateTime == null) return '--';

    const thu = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };

    return '${thu[dateTime.weekday]}-${dateTime.day}';
  }

  String _formatPlanHour(DateTime? dateTime) {
    if (dateTime == null) return '--:--';

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatPlanTime(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa có thời gian';

    return '${_formatPlanDay(dateTime)}, ${_formatPlanHour(dateTime)}';
  }

  String _planActionText({
    required bool pinned,
    required String status,
    required bool gpsConfirmed,
  }) {
    if (!pinned) return '';

    final cleanStatus = status.toLowerCase();

    if (gpsConfirmed ||
        cleanStatus == 'visited' ||
        cleanStatus == 'completed') {
      return 'Đánh giá';
    }

    if (cleanStatus == 'skipped') {
      return 'Đặt lại';
    }

    return 'Xem vị trí';
  }

  String _firstText(List<dynamic> values, {required String fallback}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  String _formatTime(String raw) {
    if (raw.trim().isEmpty) {
      return 'Chưa có thời gian';
    }

    try {
      final dateTime = DateTime.parse(raw).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '${dateTime.day}/${dateTime.month}, $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  bool _isActiveItem(dynamic status) {
    final text = status?.toString().toLowerCase() ?? '';

    return text == 'active' || text == 'current' || text == 'ongoing';
  }

  Future<List<PostModel>> _loadUserPosts(
    String userId,
    MyProfile profile,
    bool mutualFollow,
  ) async {
    final currentUserId = _client.auth.currentUser?.id;
    try {
      var query = _client
          .from('posts')
          .select(
            'id, content, title, visibility, like_count, comment_count, created_at, location_name,'
            'post_media(url, display_order)',
          )
          .eq('profile_id', userId)
          .eq('status', 'active');

      // Lọc bài viết theo quyền riêng tư nếu không phải chính mình xem
      if (userId != currentUserId) {
        if (mutualFollow) {
          // Follower (người đang follow profile owner) thấy public + follower
          query = query.inFilter('visibility', ['public', 'follower']);
        } else {
          // Người chưa follow chỉ thấy public
          query = query.eq('visibility', 'public');
        }
      }
      // Chính mình → không lọc, thấy tất cả kể cả private

      final rows = await query.order('created_at', ascending: false).limit(20);

      final postList = rows as List;
      final postIds = postList
          .map((r) => (r as Map<String, dynamic>)['id'] as int)
          .toList();
      final hashtagMap = await _loadHashtagsForPosts(postIds);

      return Future.wait(
        postList.map((raw) async {
          final map = raw as Map<String, dynamic>;
          final postId = (map['id'] as int?) ?? 0;

          String? firstMediaUrl;
          final media = map['post_media'];

          if (media is List && media.isNotEmpty) {
            final sorted =
                List<Map<String, dynamic>>.from(
                  media.map((m) => m as Map<String, dynamic>),
                )..sort((a, b) {
                  final aO = (a['display_order'] as int?) ?? 0;
                  final bO = (b['display_order'] as int?) ?? 0;
                  return aO.compareTo(bO);
                });

            firstMediaUrl = sorted.first['url']?.toString();
          }

          final content = map['content']?.toString().trim() ?? '';
          final title = map['title']?.toString().trim() ?? '';
          final createdAtRaw = map['created_at']?.toString() ?? '';

          return PostModel(
            id: postId,
            authorId: userId,
            tenNguoiDang: profile.displayName,
            anhDaiDienNguoiDang: profile.avatarUrl.isNotEmpty
                ? profile.avatarUrl
                : null,
            thoiGian: _timeAgo(createdAtRaw),
            caption: content.isNotEmpty
                ? content
                : (title.isNotEmpty ? title : null),
            danhSachAnh: firstMediaUrl != null ? [firstMediaUrl] : const [],
            viTri: _emptyToNull(map['location_name']),
            danhSachHashTag: hashtagMap[postId] ?? const [],
            soLuotThich: (map['like_count'] as int?) ?? 0,
            soLuotBinhLuan: (map['comment_count'] as int?) ?? 0,
            daThich: currentUserId != null
                ? await _isPostLikedByMe(postId, currentUserId)
                : false,
            laBaiVietCuaToi: userId == currentUserId,
            createdAt: DateTime.tryParse(createdAtRaw)?.toLocal(),
            visibility: map['visibility']?.toString(),
          );
        }).toList(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<Map<int, List<String>>> _loadHashtagsForPosts(
    List<int> postIds,
  ) async {
    if (postIds.isEmpty) return {};
    try {
      final phRows = await _client
          .from('post_hashtags')
          .select('post_id, hashtag_id')
          .inFilter('post_id', postIds);

      if ((phRows as List).isEmpty) return {};

      final hashtagIds = phRows.map((r) => r['hashtag_id']).toSet().toList();

      final hRows = await _client
          .from('hashtags')
          .select('id, name')
          .inFilter('id', hashtagIds);

      final nameById = <int, String>{};
      for (final Map<String, dynamic> h in hRows as List) {
        nameById[(h['id'] as num).toInt()] = h['name']?.toString() ?? '';
      }

      final result = <int, List<String>>{};
      for (final Map<String, dynamic> ph in phRows) {
        final postId = (ph['post_id'] as num).toInt();
        final hashtagId = (ph['hashtag_id'] as num).toInt();
        final name = nameById[hashtagId];
        if (name != null && name.isNotEmpty) {
          result.putIfAbsent(postId, () => []).add(name);
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<bool> _isPostLikedByMe(int postId, String userId) async {
    if (postId == 0) {
      return false;
    }

    try {
      final row = await _client
          .from('post_likes')
          .select('post_id')
          .eq('post_id', postId)
          .eq('profile_id', userId)
          .maybeSingle();

      return row != null;
    } catch (_) {
      return false;
    }
  }

  String _timeAgo(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String? _emptyToNull(dynamic value) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }
}
