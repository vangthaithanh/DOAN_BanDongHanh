import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../social/data/models/post_model.dart';

class HomeFeedService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PostModel>> loadFeed() async {
    final hasInterests = await _hasSelectedInterests();

    // Nếu user chưa chọn sở thích/gợi ý:
    // Không đi qua tầng recommended, xuống thẳng public feed.
    if (!hasInterests) {
      return _loadPublicPosts();
    }

    // Nếu user đã chọn sở thích:
    // Ưu tiên bài gợi ý trước, nhưng vẫn gộp thêm bài public mới.
    // Như vậy user không bị "nhốt" trong feed gợi ý.
    final recommendedPosts = await _loadRecommendedPosts();
    final publicPosts = await _loadPublicPosts();

    return _mergePosts(
      recommendedPosts: recommendedPosts,
      publicPosts: publicPosts,
    );
  }

  Future<bool> _hasSelectedInterests() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final rows = await _client
          .from('profile_interests')
          .select('option_code')
          .eq('profile_id', user.id)
          .limit(1);

      return (rows as List).isNotEmpty;
    } catch (_) {
      // Nếu lỗi RLS hoặc lỗi mạng, cho user xuống public feed
      // để tránh bị kẹt ở tầng recommended.
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
      // Nếu view recommended lỗi, không làm chết trang chủ.
      // Feed public vẫn sẽ được load ở loadFeed().
      return [];
    }
  }

  Future<List<PostModel>> _loadPublicPosts() async {
    final rows = await _client
        .from('home_public_posts')
        .select()
        .order('created_at', ascending: false)
        .limit(50);

    return _mapRows(rows as List);
  }

  List<PostModel> _mergePosts({
    required List<PostModel> recommendedPosts,
    required List<PostModel> publicPosts,
  }) {
    final mergedPosts = <PostModel>[];
    final seenPostIds = <int>{};

    for (final post in recommendedPosts) {
      if (seenPostIds.add(post.id)) {
        mergedPosts.add(post);
      }
    }

    for (final post in publicPosts) {
      if (seenPostIds.add(post.id)) {
        mergedPosts.add(post);
      }
    }

    return mergedPosts;
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
      final isLiked = currentUserId == null
          ? false
          : await _isPostLikedByMe(postId, currentUserId);

      posts.add(
        PostModel(
          id: postId,
          tenNguoiDang: _firstText([
            row['author_nickname'],
          ], fallback: 'Người dùng'),
          anhDaiDienNguoiDang: _emptyToNull(row['author_avatar_url']),
          thoiGian: _timeAgo(createdAtRaw),
          caption: _caption(row),
          danhSachAnh: mediaUrl.isEmpty ? const [] : [mediaUrl],
          viTri:
              _emptyToNull(row['location_name']) ??
              _emptyToNull(row['tagged_places']),
          danhSachHashTag: _parseHashTags(
            row['matched_hashtags'] ?? row['hashtags'],
          ),
          soLuotThich: _asInt(row['like_count']),
          soLuotBinhLuan: _asInt(row['comment_count']),
          daThich: isLiked,
          laBaiVietCuaToi: isMine,
          createdAt: DateTime.tryParse(createdAtRaw)?.toLocal(),
          visibility: row['visibility']?.toString(),
        ),
      );
    }

    return posts;
  }

  Future<bool> _isPostLikedByMe(int postId, String userId) async {
    if (postId == 0 || userId.isEmpty) {
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

  String? _caption(Map<String, dynamic> row) {
    final title = row['title']?.toString().trim() ?? '';
    final content = row['content']?.toString().trim() ?? '';

    if (title.isEmpty && content.isEmpty) {
      return null;
    }

    if (title.isNotEmpty && content.isNotEmpty && title != content) {
      return '$title\n$content';
    }

    return content.isNotEmpty ? content : title;
  }

  List<String> _parseHashTags(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return const [];
    }

    return text
        .split(RegExp(r'[\s,]+'))
        .map((item) => item.trim().replaceFirst(RegExp(r'^#+'), ''))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _timeAgo(dynamic value) {
    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty) {
      return '';
    }

    try {
      final createdAt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(createdAt);

      if (diff.inMinutes < 1) {
        return 'Vừa xong';
      }

      if (diff.inHours < 1) {
        return '${diff.inMinutes} phút trước';
      }

      if (diff.inDays < 1) {
        return '${diff.inHours} giờ trước';
      }

      if (diff.inDays < 7) {
        return '${diff.inDays} ngày trước';
      }

      final weeks = diff.inDays ~/ 7;

      if (weeks < 5) {
        return '$weeks tuần trước';
      }

      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } catch (_) {
      return raw;
    }
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
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

  String? _emptyToNull(dynamic value) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }
}
