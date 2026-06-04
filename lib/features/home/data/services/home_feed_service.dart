import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../social/data/models/post_model.dart';

class HomeFeedService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PostModel>> loadFeed() async {
    final recommendedPosts = await _loadRecommendedPosts();

    if (recommendedPosts.isNotEmpty) {
      return recommendedPosts;
    }

    return _loadPublicPosts();
  }

  Future<List<PostModel>> _loadRecommendedPosts() async {
    final rows = await _client
        .from('home_recommended_posts')
        .select()
        .order('score', ascending: false)
        .order('created_at', ascending: false)
        .limit(50);

    return _mapRows(rows as List);
  }

  Future<List<PostModel>> _loadPublicPosts() async {
    final rows = await _client
        .from('home_public_posts')
        .select()
        .order('created_at', ascending: false)
        .limit(50);

    return _mapRows(rows as List);
  }

  List<PostModel> _mapRows(List rows) {
    final currentUserId = _client.auth.currentUser?.id;

    return rows.map((raw) {
      final row = raw as Map<String, dynamic>;
      final authorProfileId = row['author_profile_id']?.toString() ?? '';
      final mediaUrl = row['first_media_url']?.toString().trim() ?? '';

      return PostModel(
        id: _asInt(row['post_id']),
        tenNguoiDang: _firstText([
          row['author_nickname'],
        ], fallback: 'Người dùng'),
        anhDaiDienNguoiDang: _emptyToNull(row['author_avatar_url']),
        thoiGian: _timeAgo(row['created_at']),
        caption: _caption(row),
        danhSachAnh: mediaUrl.isEmpty ? const [] : [mediaUrl],
        viTri: _emptyToNull(row['tagged_places']),
        danhSachHashTag: _parseHashTags(
          row['matched_hashtags'] ?? row['hashtags'],
        ),
        soLuotThich: _asInt(row['like_count']),
        soLuotBinhLuan: _asInt(row['comment_count']),
        daThich: row['is_liked_by_me'] == true,
        laBaiVietCuaToi:
            currentUserId != null && authorProfileId == currentUserId,
      );
    }).toList();
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
