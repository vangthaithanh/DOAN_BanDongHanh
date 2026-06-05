import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/time_ago.dart';
import '../../../social/data/models/post_model.dart';
import '../../../social/presentation/widgets/post_card.dart';

class TrangKhoLuuTruPage extends StatefulWidget {
  const TrangKhoLuuTruPage({super.key});

  @override
  State<TrangKhoLuuTruPage> createState() => _TrangKhoLuuTruPageState();
}

class _TrangKhoLuuTruPageState extends State<TrangKhoLuuTruPage> {
  final SupabaseClient _client = Supabase.instance.client;

  late Future<List<PostModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadArchivedPosts();
  }

  void _reload() {
    setState(() {
      _future = _loadArchivedPosts();
    });
  }

  Future<List<PostModel>> _loadArchivedPosts() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xem Kho lưu trữ.');
    }

    final rows = await _client
        .from('posts')
        .select('''
          *,
          profiles:profile_id (nickname, avatar_url),
          post_media(url, display_order)
        ''')
        .eq('profile_id', user.id)
        .eq('status', 'archived')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((raw) => _mapPost(raw as Map<String, dynamic>, user.id))
        .toList();
  }

  PostModel _mapPost(Map<String, dynamic> row, String currentUserId) {
    final authorId = row['profile_id']?.toString() ?? '';
    final media = List<Map<String, dynamic>>.from(
      row['post_media'] as List? ?? [],
    );

    media.sort((a, b) {
      final aOrder = _asInt(a['display_order']);
      final bOrder = _asInt(b['display_order']);
      return aOrder.compareTo(bOrder);
    });

    final imageUrls = media
        .map((item) => item['url']?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    final createdAtRaw = row['created_at']?.toString().trim() ?? '';
    final createdAt = DateTime.tryParse(createdAtRaw)?.toLocal();

    return PostModel(
      id: _asInt(row['id']),
      authorId: authorId,
      tenNguoiDang: row['profiles']?['nickname']?.toString() ?? 'Người dùng',
      anhDaiDienNguoiDang: _emptyToNull(row['profiles']?['avatar_url']),
      thoiGian: createdAt == null ? '' : timeAgo(createdAt),
      caption: _caption(row),
      danhSachAnh: imageUrls,
      viTri:
          _emptyToNull(row['location_name']) ??
          _emptyToNull(row['tagged_places']),
      danhSachHashTag: _parseHashTags(
        row['hashtags'] ?? row['matched_hashtags'],
      ),
      soLuotThich: _asInt(row['like_count']),
      soLuotBinhLuan: _asInt(row['comment_count']),
      daThich: false,
      laBaiVietCuaToi: authorId == currentUserId,
      createdAt: createdAt,
      visibility: row['visibility']?.toString(),
      status: row['status']?.toString(),
      isArchived: true,
    );
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
    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value
          .map(
            (item) => item.toString().trim().replaceFirst(RegExp(r'^#+'), ''),
          )
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return const [];
    }

    return text
        .split(RegExp(r'[\s,]+'))
        .map((item) => item.trim().replaceFirst(RegExp(r'^#+'), ''))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String? _emptyToNull(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') {
      return null;
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kho lưu trữ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<PostModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snapshot.error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _reload,
                        child: const Text('Tải lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final posts = snapshot.data ?? const <PostModel>[];

            if (posts.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        color: Colors.white38,
                        size: 54,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Chưa có bài viết đã lưu trữ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Bài viết bạn lưu trữ từ trang cá nhân sẽ xuất hiện ở đây.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return PostCard(
                    post: posts[index],
                    cheDoKhoLuuTru: true,
                    hienThiTuongTac: false,
                    onPostModified: _reload,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
