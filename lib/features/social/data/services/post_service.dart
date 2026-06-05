import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/binh_luan_model.dart';
import '../models/post_model.dart';

class PostLikeResult {
  final bool liked;
  final int likeCount;

  const PostLikeResult({required this.liked, required this.likeCount});
}

class PostService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<PostModel> loadPostById(int postId) async {
    final currentUserId = _client.auth.currentUser?.id;

    final row = await _wrapSupabaseError(() {
      return _client
          .from('posts')
          .select(
            'id, profile_id, title, content, visibility, like_count, comment_count, created_at, location_name',
          )
          .eq('id', postId)
          .maybeSingle();
    });

    if (row == null) {
      throw Exception('Không tìm thấy bài viết');
    }

    final authorProfileId = row['profile_id']?.toString() ?? '';
    final profile = await _loadPublicProfile(authorProfileId);
    final mediaUrls = await _loadPostMedia(postId);
    final hashtags = await _loadPostHashTags(postId);
    final taggedLocationName = await _loadTaggedPlaces(postId);
    final locationName =
        _emptyToNull(row['location_name']) ?? taggedLocationName;
    final liked = await _isLikedByMe(postId);
    final createdAtRaw = row['created_at']?.toString().trim() ?? '';

    return PostModel(
      id: _asInt(row['id']),
      tenNguoiDang: _firstText([profile?['nickname']], fallback: 'Người dùng'),
      anhDaiDienNguoiDang: _emptyToNull(profile?['avatar_url']),
      thoiGian: _timeAgo(createdAtRaw),
      caption: _caption(row),
      danhSachAnh: mediaUrls,
      viTri: locationName,
      danhSachHashTag: hashtags,
      soLuotThich: await _countPostLikes(postId, row['like_count']),
      soLuotBinhLuan: await _countPostComments(postId, row['comment_count']),
      daThich: liked,
      laBaiVietCuaToi:
          currentUserId != null && authorProfileId == currentUserId,
      createdAt: DateTime.tryParse(createdAtRaw)?.toLocal(),
      visibility: row['visibility']?.toString(),
    );
  }

  Future<PostLikeResult> toggleLike(int postId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final existing = await _wrapSupabaseError(() {
      return _client
          .from('post_likes')
          .select('post_id')
          .eq('post_id', postId)
          .eq('profile_id', user.id)
          .maybeSingle();
    });

    if (existing == null) {
      await _wrapSupabaseError(() {
        return _client.from('post_likes').insert({
          'post_id': postId,
          'profile_id': user.id,
        });
      });
    } else {
      await _wrapSupabaseError(() {
        return _client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('profile_id', user.id);
      });
    }

    final liked = existing == null;
    final likeCount = await _countPostLikes(postId, null);

    return PostLikeResult(liked: liked, likeCount: likeCount);
  }

  Future<List<BinhLuanModel>> loadComments(int postId) async {
    final rows = await _wrapSupabaseError(() {
      return _client
          .from('comments')
          .select('id, post_id, profile_id, content, created_at')
          .eq('post_id', postId)
          .eq('status', 'active')
          .order('created_at', ascending: false);
    });

    final comments = <BinhLuanModel>[];

    for (final raw in rows as List) {
      final row = raw as Map<String, dynamic>;
      final profile = await _loadPublicProfile(row['profile_id']?.toString());

      comments.add(
        BinhLuanModel(
          id: _asInt(row['id']),
          postId: _asInt(row['post_id']),
          tenNguoiBinhLuan: _firstText([
            profile?['nickname'],
          ], fallback: 'Người dùng'),
          anhDaiDienNguoiBinhLuan: _emptyToNull(profile?['avatar_url']),
          thoiGian: _timeAgo(row['created_at']),
          noiDung: row['content']?.toString() ?? '',
          danhSachTraLoi: const [],
        ),
      );
    }

    return comments;
  }

  Future<BinhLuanModel> addComment({
    required int postId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final cleanContent = content.trim();

    if (cleanContent.isEmpty) {
      throw Exception('Vui lòng nhập bình luận');
    }

    final row = await _wrapSupabaseError(() {
      return _client
          .from('comments')
          .insert({
            'post_id': postId,
            'profile_id': user.id,
            'content': cleanContent,
            'status': 'active',
          })
          .select('id, post_id, profile_id, content, created_at')
          .single();
    });

    final profile = await _loadPublicProfile(user.id);

    return BinhLuanModel(
      id: _asInt(row['id']),
      postId: _asInt(row['post_id']),
      tenNguoiBinhLuan: _firstText([
        profile?['nickname'],
      ], fallback: 'Người dùng'),
      anhDaiDienNguoiBinhLuan: _emptyToNull(profile?['avatar_url']),
      thoiGian: 'Vừa xong',
      noiDung: row['content']?.toString() ?? cleanContent,
      danhSachTraLoi: const [],
    );
  }

  Future<int> createPost({
    required String content,
    required String visibility,
    String? imagePath,
    String? locationName,
    List<String> hashtags = const [],
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final cleanContent = content.trim();
    final cleanLocationName = locationName?.trim() ?? '';
    final now = DateTime.now().toIso8601String();
    final postRow = await _wrapSupabaseError(() {
      return _client
          .from('posts')
          .insert({
            'profile_id': user.id,
            'title': null,
            'content': cleanContent.isEmpty ? null : cleanContent,
            'visibility': visibility,
            'like_count': 0,
            'comment_count': 0,
            'share_count': 0,
            'status': 'active',
            'location_name': cleanLocationName.isEmpty
                ? null
                : cleanLocationName,
            'created_at': now,
            'updated_at': now,
          })
          .select('id')
          .single();
    });

    final postId = _asInt(postRow['id']);

    if (imagePath != null) {
      final mediaUrl = await _uploadPostImage(user.id, File(imagePath));

      await _wrapSupabaseError(() {
        return _client.from('post_media').insert({
          'post_id': postId,
          'media_type': 'image',
          'url': mediaUrl,
          'caption': cleanContent.isEmpty ? null : cleanContent,
          'display_order': 0,
        });
      });
    }

    await _saveHashTags(postId, hashtags);
    await _saveLocationTag(postId, locationName);

    return postId;
  }

  Future<void> updatePost({
    required int postId,
    String? content,
    String? visibility,
    List<String>? hashtags,
    String? locationName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final fields = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (content != null) fields['content'] = content.trim();
    if (visibility != null) fields['visibility'] = visibility;
    if (locationName != null) {
      fields['location_name'] = locationName.trim().isEmpty ? null : locationName.trim();
    }

    await _wrapSupabaseError(() {
      return _client
          .from('posts')
          .update(fields)
          .eq('id', postId)
          .eq('profile_id', user.id);
    });

    if (hashtags != null) {
      await _wrapSupabaseError(() {
        return _client.from('post_hashtags').delete().eq('post_id', postId);
      });

      for (final tag in hashtags) {
        final clean = tag.trim().toLowerCase();
        if (clean.isEmpty) continue;

        final h = await _wrapSupabaseError(() {
          return _client
              .from('hashtags')
              .upsert({'name': clean}, onConflict: 'name')
              .select('id')
              .single();
        });

        await _wrapSupabaseError(() {
          return _client.from('post_hashtags').upsert({
            'post_id': postId,
            'hashtag_id': _asInt(h['id']),
          }, onConflict: 'post_id,hashtag_id');
        });
      }
    }

    if (locationName != null) {
      await _wrapSupabaseError(() {
        return _client.from('post_place_tags').delete().eq('post_id', postId);
      });
      await _saveLocationTag(postId, locationName);
    }
  }

  Future<void> deletePost(int postId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    await _wrapSupabaseError(() {
      return _client
          .from('posts')
          .update({'status': 'hidden'})
          .eq('id', postId)
          .eq('profile_id', user.id);
    });
  }

  Future<Map<String, dynamic>?> _loadPublicProfile(String? profileId) async {
    final cleanId = profileId?.trim() ?? '';

    if (cleanId.isEmpty) {
      return null;
    }

    try {
      return await _client
          .from('public_profiles_safe')
          .select('id, nickname, avatar_url')
          .eq('id', cleanId)
          .maybeSingle();
    } catch (_) {
      try {
        return await _client
            .from('profiles')
            .select('id, nickname, avatar_url')
            .eq('id', cleanId)
            .maybeSingle();
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<String>> _loadPostMedia(int postId) async {
    try {
      final rows = await _client
          .from('post_media')
          .select('url, display_order, created_at')
          .eq('post_id', postId)
          .order('display_order', ascending: true)
          .order('created_at', ascending: true);

      return (rows as List)
          .map((raw) => (raw as Map<String, dynamic>)['url']?.toString() ?? '')
          .where((url) => url.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _loadPostHashTags(int postId) async {
    try {
      final rows = await _client
          .from('post_hashtags')
          .select('hashtags(name)')
          .eq('post_id', postId);

      return (rows as List)
          .map((raw) {
            final row = raw as Map<String, dynamic>;
            final hashtag = row['hashtags'];

            if (hashtag is Map<String, dynamic>) {
              return hashtag['name']?.toString() ?? '';
            }

            return '';
          })
          .where((tag) => tag.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String?> _loadTaggedPlaces(int postId) async {
    try {
      final rows = await _client
          .from('post_place_tags')
          .select('places(name)')
          .eq('post_id', postId);

      final names = (rows as List)
          .map((raw) {
            final row = raw as Map<String, dynamic>;
            final place = row['places'];

            if (place is Map<String, dynamic>) {
              return place['name']?.toString() ?? '';
            }

            return '';
          })
          .where((name) => name.trim().isNotEmpty)
          .toList();

      return names.isEmpty ? null : names.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isLikedByMe(int postId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final row = await _client
          .from('post_likes')
          .select('post_id')
          .eq('post_id', postId)
          .eq('profile_id', user.id)
          .maybeSingle();

      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<int> _countPostLikes(int postId, dynamic fallback) async {
    try {
      final rows = await _client
          .from('post_likes')
          .select('post_id')
          .eq('post_id', postId);

      return (rows as List).length;
    } catch (_) {
      return _asInt(fallback);
    }
  }

  Future<int> _countPostComments(int postId, dynamic fallback) async {
    try {
      final rows = await _client
          .from('comments')
          .select('post_id')
          .eq('post_id', postId)
          .eq('status', 'active');

      return (rows as List).length;
    } catch (_) {
      return _asInt(fallback);
    }
  }

  Future<String> _uploadPostImage(String userId, File file) async {
    if (!file.existsSync()) {
      throw Exception('Không tìm thấy ảnh đã chọn');
    }

    final ext = _extension(file.path);
    final path = '$userId/post_${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await _client.storage
          .from('post-media')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
    } on StorageException catch (e) {
      if (e.statusCode == '403' || e.message.toLowerCase().contains('policy')) {
        throw Exception(
          'Supabase chưa cấp quyền upload ảnh bài viết cho tài khoản này',
        );
      }

      throw Exception(e.message);
    }

    return _client.storage.from('post-media').getPublicUrl(path);
  }

  Future<void> _saveHashTags(int postId, List<String> hashtags) async {
    final cleanTags = hashtags
        .map(_normalizeHashTag)
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    for (final tag in cleanTags) {
      final row = await _findOrCreateHashTag(tag);

      await _wrapSupabaseError(() {
        return _client.from('post_hashtags').insert({
          'post_id': postId,
          'hashtag_id': _asInt(row['id']),
        });
      });
    }
  }

  Future<Map<String, dynamic>> _findOrCreateHashTag(String tag) async {
    final existing = await _wrapSupabaseError(() {
      return _client
          .from('hashtags')
          .select('id')
          .eq('name', tag)
          .maybeSingle();
    });

    if (existing != null) {
      return existing;
    }

    try {
      return await _wrapSupabaseError(() {
        return _client
            .from('hashtags')
            .insert({'name': tag, 'status': 'active'})
            .select('id')
            .single();
      });
    } on Exception {
      final retry = await _wrapSupabaseError(() {
        return _client
            .from('hashtags')
            .select('id')
            .eq('name', tag)
            .maybeSingle();
      });

      if (retry != null) {
        return retry;
      }

      rethrow;
    }
  }

  Future<void> _saveLocationTag(int postId, String? locationName) async {
    final cleanName = locationName?.trim() ?? '';

    if (cleanName.isEmpty) {
      return;
    }

    final place = await _client
        .from('places')
        .select('id')
        .ilike('name', cleanName)
        .maybeSingle();

    if (place == null) {
      return;
    }

    await _wrapSupabaseError(() {
      return _client.from('post_place_tags').insert({
        'post_id': postId,
        'place_id': _asInt(place['id']),
      });
    });
  }

  String _normalizeHashTag(String value) {
    return value
        .trim()
        .replaceFirst(RegExp(r'^#+'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\w\u00C0-\u1EF9]+'), '')
        .toLowerCase();
  }

  String _extension(String path) {
    final ext = path.split('.').last.toLowerCase();

    if (ext.isEmpty || ext.length > 5) {
      return 'jpg';
    }

    return ext;
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

      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } catch (_) {
      return raw;
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

  String? _emptyToNull(dynamic value) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  Future<T> _wrapSupabaseError<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.toLowerCase().contains('policy')) {
        throw Exception(
          'Supabase chưa cấp quyền cho thao tác bài viết. Cần chạy SQL RLS patch cho posts/post_likes/comments.',
        );
      }

      throw Exception(e.message);
    }
  }
}
