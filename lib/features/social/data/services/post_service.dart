import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class PostService {
  final SupabaseClient _client = Supabase.instance.client;

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
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final fields = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (content != null) fields['content'] = content.trim();
    if (visibility != null) fields['visibility'] = visibility;

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
          return _client.from('post_hashtags').upsert(
            {'post_id': postId, 'hashtag_id': _asInt(h['id'])},
            onConflict: 'post_id,hashtag_id',
          );
        });
      }
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

  Future<T> _wrapSupabaseError<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.toLowerCase().contains('policy')) {
        throw Exception(
          'Supabase chưa cấp quyền tạo bài viết. Cần chạy SQL RLS patch cho posts/post_media/hashtags.',
        );
      }

      throw Exception(e.message);
    }
  }
}
