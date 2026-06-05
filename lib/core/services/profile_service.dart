import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/social/data/models/post_model.dart';

/// NOTE SỬA:
/// Service này dùng cho trang cá nhân.
/// Query khớp RLS/database hiện tại:
/// follows: follower_id, following_id
/// friends: profile_id1, profile_id2
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
  final String title;
  final String timeText;
  final String actionText;
  final bool isActive;

  const ProfilePlanItemData({
    required this.id,
    required this.title,
    required this.timeText,
    required this.actionText,
    required this.isActive,
  });
}

class ProfilePlanGroupData {
  final String id;
  final String name;
  final String routeText;
  final List<ProfilePlanItemData> items;

  const ProfilePlanGroupData({
    required this.id,
    required this.name,
    required this.routeText,
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
    bool mutual = false;
    if (currentUserId != null && currentUserId != profileId) {
      isFollowing = await _checkIsFollowing(currentUserId, profileId);
      // Kiểm tra xem người đó có theo dõi lại mình không để xác định mutual follow
      final theyFollowMe = await _checkIsFollowing(profileId, currentUserId);
      mutual = isFollowing && theyFollowMe;
    } else if (currentUserId == profileId) {
      mutual = true; // Mình xem mình thì coi như mutual để thấy hết
    }

    final posts = await _loadUserPosts(profileId, profile, mutual);

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

  Future<int> _countFriends(String userId) async {
    try {
      final rows1 = await _client
          .from('friends')
          .select('id')
          .eq('profile_id1', userId)
          .eq('status', 'active');

      final rows2 = await _client
          .from('friends')
          .select('id')
          .eq('profile_id2', userId)
          .eq('status', 'active');

      return (rows1 as List).length + (rows2 as List).length;
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
          .neq('status', 'deleted');

      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<ProfilePlanGroupData>> _loadPlans(String userId) async {
    try {
      final planRows = await _client
          .from('itineraries')
          .select('*')
          .eq('profile_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      final plans = <ProfilePlanGroupData>[];

      for (final rawPlan in planRows as List) {
        final plan = rawPlan as Map<String, dynamic>;
        final planId = plan['id']?.toString() ?? '';

        final items = await _loadPlanItems(planId);

        plans.add(
          ProfilePlanGroupData(
            id: planId,
            name: _firstText([plan['title'], plan['name']], fallback: 'Plan'),
            routeText: _firstText([
              plan['route_text'],
              plan['destination'],
              plan['description'],
            ], fallback: 'Chưa có tuyến'),
            items: items,
          ),
        );
      }

      return plans;
    } catch (_) {
      return [];
    }
  }

  Future<List<ProfilePlanItemData>> _loadPlanItems(String itineraryId) async {
    if (itineraryId.isEmpty) {
      return [];
    }

    try {
      final itemRows = await _client
          .from('itinerary_items')
          .select('*')
          .eq('itinerary_id', itineraryId)
          .order('sort_order', ascending: true)
          .limit(30);

      final items = <ProfilePlanItemData>[];

      for (final rawItem in itemRows as List) {
        final item = rawItem as Map<String, dynamic>;

        items.add(
          ProfilePlanItemData(
            id: item['id']?.toString() ?? '',
            title: _firstText([
              item['title'],
              item['name'],
              item['place_name'],
            ], fallback: 'Địa điểm'),
            timeText: _formatTime(
              _firstText([
                item['start_time'],
                item['scheduled_at'],
                item['time_text'],
              ], fallback: ''),
            ),
            actionText: _firstText([
              item['action_text'],
              item['action'],
            ], fallback: 'Xem điểm đến'),
            isActive: _isActiveItem(item['status']),
          ),
        );
      }

      return items;
    } catch (_) {
      return [];
    }
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

  Future<List<PostModel>> _loadUserPosts(String userId, MyProfile profile, bool mutualFollow) async {
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
          // Nếu mutual follow, thấy được public và follower
          query = query.inFilter('visibility', ['public', 'follower']);
        } else {
          // Nếu không, chỉ thấy public
          query = query.eq('visibility', 'public');
        }
      }

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
            daThich: currentUserId != null ? await _isPostLikedByMe(postId, currentUserId) : false,
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
      List<int> postIds) async {
    if (postIds.isEmpty) return {};
    try {
      final phRows = await _client
          .from('post_hashtags')
          .select('post_id, hashtag_id')
          .inFilter('post_id', postIds);

      if ((phRows as List).isEmpty) return {};

      final hashtagIds = phRows
          .map((r) => r['hashtag_id'])
          .toSet()
          .toList();

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
