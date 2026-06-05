import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../social/data/models/post_model.dart';

class HomeFeedService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PostModel>> loadFeed() async {
    final user = _client.auth.currentUser;
    final hasInterests = await _hasSelectedInterests();
    final blockedIds = await _getBlockedIds();

    // 1. Load bài viết Public (từ view)
    final publicPosts = await _loadPublicPosts();

    // 2. Load bài viết từ Mutual Follows (nếu đã đăng nhập)// D:/Mobile/DOAN_BanDongHanh/lib/features/home/data/services/home_feed_service.dart

    Future<List<PostModel>> loadMutualFollowerPosts(String userId) async {
      final mutualIds = await _getMutualFollowIds(userId);
      if (mutualIds.isEmpty) return [];

      try {
        final rows = await _client
            .from('posts')
            .select('''
            *,
            profiles:profile_id (nickname, avatar_url),
            post_media(url, display_order)
          ''')
            .inFilter('profile_id', mutualIds)
        // CHỈNH SỬA TẠI ĐÂY: Lấy cả bài viết chế độ 'người theo dõi' và 'bạn bè'
            .inFilter('visibility', ['follower', 'friend'])
            .eq('status', 'active')
            .order('created_at', ascending: false)
            .limit(20);

        return _mapRawPosts(rows as List);
      } catch (e) {
        return [];
      }
    }
    List<PostModel> followerPosts = [];
    if (user != null) {
      followerPosts = await loadMutualFollowerPosts(user.id);
    }

    // 3. Load bài viết gợi ý (nếu có sở thích)
    List<PostModel> recommendedPosts = [];
    if (hasInterests) {
      recommendedPosts = await _loadRecommendedPosts();
    }

    // Gộp tất cả lại và loại bỏ trùng lặp
    final merged = _mergeAllPosts(
      recommended: recommendedPosts,
      public: publicPosts,
      followers: followerPosts,
      blockedIds: blockedIds,
    );

    if (merged.isEmpty) return merged;
    final tagMap = await _batchLoadTags(merged.map((p) => p.id).toList());
    if (tagMap.isEmpty) return merged;
    return merged.map((p) {
      final tags = tagMap[p.id];
      if (tags == null || tags.isEmpty) return p;
      return p.copyWith(danhSachBanBeDuocTag: tags);
    }).toList();
  }

  Future<bool> _hasSelectedInterests() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      final rows = await _client
          .from('profile_interests')
          .select('option_code')
          .eq('profile_id', user.id)
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<PostModel>> _loadRecommendedPosts() async {
    try {
      final rows = await _client
          .from('home_recommended_posts')
          .select()
          .order('score', ascending: false)
          .order('created_at', ascending: false)
          .limit(50);
      return _mapRows(rows as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<PostModel>> _loadPublicPosts() async {
    try {
      final rows = await _client
          .from('home_public_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      return _mapRows(rows as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _getMutualFollowIds(String userId) async {
    try {
      final followingRes = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId)
          .eq('status', 'active');
      final followingIds = (followingRes as List).map((e) => e['following_id'].toString()).toSet();

      final followersRes = await _client
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId)
          .eq('status', 'active');
      final followerIds = (followersRes as List).map((e) => e['follower_id'].toString()).toSet();

      return followingIds.intersection(followerIds).toList();
    } catch (_) {
      return [];
    }
  }

  List<PostModel> _mapRawPosts(List rows) {
    final currentUserId = _client.auth.currentUser?.id;
    return rows.map((row) {
      final media = row['post_media'] as List?;
      String? firstMedia;
      if (media != null && media.isNotEmpty) {
        firstMedia = media[0]['url'];
      }
      final authorId = row['profile_id']?.toString() ?? '';
      return PostModel(
        id: _asInt(row['id']),
        authorId: authorId,
        tenNguoiDang: row['profiles']?['nickname'] ?? 'Người dùng',
        anhDaiDienNguoiDang: _emptyToNull(row['profiles']?['avatar_url']),
        thoiGian: _timeAgo(row['created_at']),
        caption: _caption(row),
        danhSachAnh: firstMedia != null ? [firstMedia] : [],
        soLuotThich: _asInt(row['like_count']),
        soLuotBinhLuan: _asInt(row['comment_count']),
        laBaiVietCuaToi: currentUserId != null && authorId == currentUserId,
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal(),
        visibility: row['visibility']?.toString(),
        status: row['status']?.toString(),
        isArchived: row['status']?.toString() == 'archived' || row['is_archived'] == true,
      );
    }).toList();
  }

  Future<List<PostModel>> _mapRows(List rows) async {
    final currentUserId = _client.auth.currentUser?.id;
    final posts = <PostModel>[];
    for (final raw in rows) {
      final row = raw as Map<String, dynamic>;
      final postId = _asInt(row['post_id']);
      final authorProfileId = row['author_profile_id']?.toString() ?? '';
      final mediaUrl = row['first_media_url']?.toString().trim() ?? '';
      final createdAtRaw = row['created_at']?.toString().trim() ?? '';

      final isMine = currentUserId != null && authorProfileId == currentUserId;
      final isLiked = currentUserId == null ? false : await _isPostLikedByMe(postId, currentUserId);

      posts.add(
        PostModel(
          id: postId,
          authorId: authorProfileId,
          tenNguoiDang: _firstText([row['author_nickname']], fallback: 'Người dùng'),
          anhDaiDienNguoiDang: _emptyToNull(row['author_avatar_url']),
          thoiGian: _timeAgo(createdAtRaw),
          caption: _caption(row),
          danhSachAnh: mediaUrl.isEmpty ? const [] : [mediaUrl],
          viTri: _emptyToNull(row['location_name']) ?? _emptyToNull(row['tagged_places']),
          danhSachHashTag: _parseHashTags(row['matched_hashtags'] ?? row['hashtags']),
          soLuotThich: _asInt(row['like_count']),
          soLuotBinhLuan: _asInt(row['comment_count']),
          daThich: isLiked,
          laBaiVietCuaToi: isMine,
          createdAt: DateTime.tryParse(createdAtRaw)?.toLocal(),
          visibility: row['visibility']?.toString(),
          status: row['status']?.toString(),
          isArchived: row['status']?.toString() == 'archived' || row['is_archived'] == true,
        ),
      );
    }
    return posts;
  }

  Future<bool> _isPostLikedByMe(int postId, String userId) async {
    if (postId == 0 || userId.isEmpty) return false;
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

  Future<Map<int, List<String>>> _batchLoadTags(List<int> postIds) async {
    if (postIds.isEmpty) return {};
    try {
      final rows = await _client
          .from('post_tags')
          .select('post_id, profiles(nickname)')
          .inFilter('post_id', postIds);
      final result = <int, List<String>>{};
      for (final r in rows as List) {
        final m = r as Map<String, dynamic>;
        final postId = _asInt(m['post_id']);
        if (postId == 0) continue;
        final p = m['profiles'];
        final nick = p is Map ? p['nickname']?.toString().trim() ?? '' : '';
        if (nick.isEmpty) continue;
        result.putIfAbsent(postId, () => []).add(nick);
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<Set<String>> _getBlockedIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};
    try {
      final rows = await _client
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', user.id);
      return (rows as List)
          .map((r) => (r as Map)['blocked_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  List<PostModel> _mergeAllPosts({
    required List<PostModel> recommended,
    required List<PostModel> public,
    required List<PostModel> followers,
    Set<String> blockedIds = const {},
  }) {
    final mergedPosts = <PostModel>[];
    final seenPostIds = <int>{};
    final all = [...recommended, ...followers, ...public];

    for (final post in all) {
      if (post.status == 'archived' || post.status == 'deleted' || post.isArchived) {
        continue;
      }
      if (blockedIds.contains(post.authorId)) continue;

      if (seenPostIds.add(post.id)) {
        mergedPosts.add(post);
      }
    }

    mergedPosts.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return mergedPosts;
  }

  String? _caption(Map<String, dynamic> row) {
    final title = row['title']?.toString().trim() ?? '';
    final content = row['content']?.toString().trim() ?? '';
    if (title.isEmpty && content.isEmpty) return null;
    if (title.isNotEmpty && content.isNotEmpty && title != content) return '$title\n$content';
    return content.isNotEmpty ? content : title;
  }

  List<String> _parseHashTags(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const [];
    return text.split(RegExp(r'[\s,]+')).map((item) => item.trim().replaceFirst(RegExp(r'^#+'), '')).where((item) => item.isNotEmpty).toList();
  }

  String _timeAgo(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    try {
      final createdAt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(createdAt);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
      if (diff.inDays < 1) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } catch (_) {
      return raw;
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _firstText(List<dynamic> values, {required String fallback}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String? _emptyToNull(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
