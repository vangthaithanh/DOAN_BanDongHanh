import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/time_ago.dart';
import '../../data/models/post_model.dart';
import '../../data/services/post_service.dart';
import '../pages/trang_chinh_sua_baiviet.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final VoidCallback? onPostModified;

  // NOTE SỬA LƯU TRỮ:
  // hienThiTuongTac = false dùng ở màn xem bài đã lưu trữ: không hiện tim/cmt/gửi.
  // cheDoKhoLuuTru = true dùng ở Kho lưu trữ: menu 3 chấm đổi thành Khôi phục / Xoá / Xem.
  final bool hienThiTuongTac;
  final bool hienThiNutBaCham;
  final bool cheDoKhoLuuTru;

  const PostCard({
    super.key,
    required this.post,
    this.onComment,
    this.onShare,
    this.onTap,
    this.onPostModified,
    this.hienThiTuongTac = true,
    this.hienThiNutBaCham = true,
    this.cheDoKhoLuuTru = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  static const Color _mauXanh = Color(0xFF4AA8FF);
  static const Color _mauVien = Color(0xFF242424);

  bool _daThich = false;
  late int _soThich;
  bool _dangXuLyThich = false;
  final PostService _postService = PostService();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _expandedCaption = false;
  Timer? _timer;
  late String _timeText;

  @override
  void initState() {
    super.initState();
    _soThich = widget.post.soLuotThich;
    _daThich = widget.post.daThich;
    _initTimeText();
  }

  void _initTimeText() {
    _timer?.cancel();

    final createdAt = widget.post.createdAt;
    if (createdAt != null) {
      _timeText = timeAgo(createdAt);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final updated = timeAgo(createdAt);
        if (updated != _timeText) {
          setState(() => _timeText = updated);
        }
      });
    } else {
      _timeText = widget.post.thoiGian;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToProfile() {
    if (widget.post.authorId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.profile,
        arguments: widget.post.authorId,
      );
    }
  }

  // NOTE SỬA:
  // Làm sạch vị trí để bài viết cũ nếu đã lỡ lưu nhầm dạng:
  // {nearby_place_name: 28B Đ. số 8, latitude: ...}
  // thì ngoài trang chủ chỉ hiện địa chỉ thật.
  String? _layTenViTriSach(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty || text == 'null') {
      return null;
    }

    if (text.startsWith('{') && text.contains('nearby_place_name:')) {
      const key = 'nearby_place_name:';
      final start = text.indexOf(key) + key.length;

      final endCandidates = <int>[
        text.indexOf(', latitude:', start),
        text.indexOf(', longitude:', start),
        text.indexOf(', place_id:', start),
        text.indexOf('}', start),
      ].where((index) => index > start).toList();

      final end = endCandidates.isEmpty
          ? text.length
          : endCandidates.reduce((a, b) => a < b ? a : b);

      final location = text.substring(start, end).trim();

      if (location.isNotEmpty && location != 'null') {
        return location;
      }
    }

    return text;
  }

  // ── Visibility ───────────────────────────────────────────────────────────────

  IconData get _visibilityIcon {
    switch (widget.post.visibility) {
      case 'private':
        return Icons.lock;
      case 'follower':
        return Icons.people;
      default:
        return Icons.public;
    }
  }

  // ── Bottom sheet ─────────────────────────────────────────────────────────────

  void _showMoreSheet(BuildContext context) {
    if (widget.cheDoKhoLuuTru) {
      _showArchiveMoreSheet(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _sheetItem(
                icon: LucideIcons.pencil,
                label: 'Chỉnh sửa',
                color: Colors.white,
                onTap: () async {
                  Navigator.pop(sheetCtx);

                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrangChinhSuaBaiViet(
                        post: {
                          'post_id': widget.post.id,
                          'content': widget.post.caption,
                          'hashtags': widget.post.danhSachHashTag,
                          'visibility': widget.post.visibility ?? 'public',

                          // NOTE SỬA:
                          // Không truyền raw widget.post.viTri nữa,
                          // vì bài cũ có thể đang là "{nearby_place_name: ...}".
                          'viTri': _layTenViTriSach(widget.post.viTri),
                        },
                      ),
                    ),
                  );

                  if (result == true) {
                    widget.onPostModified?.call();
                  }
                },
              ),
              const Divider(color: Color(0xFF2B2B2B), height: 1),
              _sheetItem(
                icon: Icons.archive_outlined,
                label: 'Lưu trữ',
                color: Colors.white,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _handleArchive(context);
                },
              ),
              const Divider(color: Color(0xFF2B2B2B), height: 1),
              _sheetItem(
                icon: LucideIcons.trash2,
                label: 'Xóa bài viết',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _handleDelete(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showArchiveMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _sheetItem(
                icon: Icons.restore_rounded,
                label: 'Khôi phục về trang cá nhân',
                color: Colors.white,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _handleRestore(context);
                },
              ),
              const Divider(color: Color(0xFF2B2B2B), height: 1),
              _sheetItem(
                icon: Icons.visibility_outlined,
                label: 'Xem',
                color: Colors.white,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.archivePostDetail,
                    arguments: widget.post,
                  );
                },
              ),
              const Divider(color: Color(0xFF2B2B2B), height: 1),
              _sheetItem(
                icon: LucideIcons.trash2,
                label: 'Xoá',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _handleDeleteFromArchive(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Xóa bài viết?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Bài viết sẽ bị ẩn và không hiển thị nữa.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Huỷ', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);

              try {
                await PostService().deletePost(widget.post.id);
                widget.onPostModified?.call();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capNhatTrangThaiBaiViet(String statusMoi) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Bạn cần đăng nhập để thực hiện thao tác này.');
    }

    await _supabase
        .from('posts')
        .update({'status': statusMoi})
        .eq('id', widget.post.id)
        .eq('profile_id', userId);
  }

  void _showSnack(String message, {Color color = _mauXanh}) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _showError(Object e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _handleArchive(BuildContext context) async {
    try {
      await _capNhatTrangThaiBaiViet('archived');
      widget.onPostModified?.call();
      _showSnack('Đã đưa bài viết vào Kho lưu trữ');
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    final nav = Navigator.of(context);
    try {
      await _capNhatTrangThaiBaiViet('active');
      widget.onPostModified?.call();

      if (widget.cheDoKhoLuuTru) {
        if (!mounted) return;
        nav.pop(true);
        return;
      }

      _showSnack('Đã khôi phục bài viết về trang cá nhân');
    } catch (e) {
      _showError(e);
    }
  }

  void _handleDeleteFromArchive(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Xoá bài viết?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Bài viết sẽ bị xoá khỏi Kho lưu trữ và không hiển thị nữa.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Huỷ', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);

              try {
                await _capNhatTrangThaiBaiViet('deleted');
                widget.onPostModified?.call();
                _showSnack('Đã xoá bài viết');
              } catch (e) {
                _showError(e);
              }
            },
            child: const Text(
              'Xoá',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.soLuotThich != widget.post.soLuotThich ||
        oldWidget.post.daThich != widget.post.daThich) {
      _soThich = widget.post.soLuotThich;
      _daThich = widget.post.daThich;
    }

    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.createdAt != widget.post.createdAt ||
        oldWidget.post.thoiGian != widget.post.thoiGian) {
      _initTimeText();
    }
  }

  Future<void> _toggleThich() async {
    if (_dangXuLyThich) {
      return;
    }

    final previousLiked = _daThich;
    final previousCount = _soThich;

    setState(() {
      _dangXuLyThich = true;
      _daThich = !_daThich;
      _soThich += _daThich ? 1 : -1;
    });

    try {
      final result = await _postService.toggleLike(widget.post.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _daThich = result.liked;
        _soThich = result.likeCount;
        _dangXuLyThich = false;
      });

      // NOTE SỬA:
      // Không gọi widget.onPostModified ở đây nữa.
      // Vì nếu gọi thì trang chủ sẽ load lại toàn bộ feed mỗi lần bấm tim.
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _daThich = previousLiked;
        _soThich = previousCount;
        _dangXuLyThich = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _mauVien, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dongTieuDe(),

            if (widget.post.caption?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _captionWidget(),
            ],

            if (widget.post.danhSachHashTag.isNotEmpty) ...[
              const SizedBox(height: 6),
              _hashTags(),
            ],

            if (widget.post.danhSachBanBeDuocTag.isNotEmpty) ...[
              const SizedBox(height: 6),
              _taggedUsers(),
            ],

            if (widget.post.danhSachAnh.isNotEmpty) ...[
              const SizedBox(height: 10),
              _danhSachAnh(),
            ],

            if (widget.hienThiTuongTac) ...[
              const SizedBox(height: 12),
              _thanhTuongTac(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _dongTieuDe() {
    final avatarUrl = widget.post.anhDaiDienNguoiDang?.trim() ?? '';

    // NOTE SỬA:
    // Dùng vị trí đã làm sạch để hiển thị ngoài trang chủ.
    final viTriHienThi = _layTenViTriSach(widget.post.viTri);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _goToProfile,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: widget.post.laBaiVietCuaToi
                ? const Color(0xFF5AB2FF)
                : const Color(0xFF4AA8FF),
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    widget.post.tenNguoiDang.isEmpty
                        ? '?'
                        : widget.post.tenNguoiDang[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _goToProfile,
                child: Text(
                  widget.post.tenNguoiDang,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _timeText,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(_visibilityIcon, color: Colors.white60, size: 13),
                ],
              ),
              if (viTriHienThi != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      color: Colors.white60,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        viTriHienThi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (widget.hienThiNutBaCham &&
            (widget.post.laBaiVietCuaToi || widget.cheDoKhoLuuTru))
          GestureDetector(
            onTap: () => _showMoreSheet(context),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                LucideIcons.ellipsis,
                color: Colors.white54,
                size: 20,
              ),
            ),
          )
        else if (widget.hienThiNutBaCham && !widget.cheDoKhoLuuTru)
          const Icon(LucideIcons.ellipsis, color: Colors.white54, size: 20),
      ],
    );
  }

  Widget _captionWidget() {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );

    final text = widget.post.caption!;

    if (_expandedCaption) {
      return Padding(
        padding: const EdgeInsets.only(left: 50),
        child: Text(text, style: style),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            maxLines: 3,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
              if (painter.didExceedMaxLines)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedCaption = true;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Xem thêm',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _hashTags() {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: widget.post.danhSachHashTag
            .map(
              (tag) => Text(
                '#$tag',
                style: const TextStyle(
                  color: _mauXanh,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _taggedUsers() {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          const Icon(Icons.people_alt_outlined, color: Colors.white54, size: 14),
          ...widget.post.danhSachBanBeDuocTag.map(
            (nick) => GestureDetector(
              onTap: () async {
                try {
                  final nav = Navigator.of(context);
                  final row = await Supabase.instance.client
                      .from('profiles')
                      .select('id')
                      .eq('nickname', nick)
                      .maybeSingle();
                  final profileId = row?['id']?.toString() ?? '';
                  if (profileId.isNotEmpty) {
                    nav.pushNamed(AppRoutes.profile, arguments: profileId);
                  }
                } catch (_) {}
              },
              child: Text(
                '@$nick',
                style: const TextStyle(
                  color: _mauXanh,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _danhSachAnh() {
    final danhSach = widget.post.danhSachAnh;

    if (danhSach.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 240,
          child: _hienThiAnh(danhSach[0]),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: danhSach.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 200,
              height: 220,
              child: _hienThiAnh(danhSach[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _hienThiAnh(String duongDan) {
    if (duongDan.startsWith('http://') || duongDan.startsWith('https://')) {
      return Image.network(
        duongDan,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _anhLoi(),
      );
    }

    if (File(duongDan).existsSync()) {
      return Image.file(File(duongDan), fit: BoxFit.cover);
    }

    return Image.asset(
      duongDan,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _anhLoi(),
    );
  }

  Widget _anhLoi() {
    return Container(
      color: const Color(0xFF222222),
      alignment: Alignment.center,
      child: const Icon(LucideIcons.image, color: Colors.white38, size: 32),
    );
  }

  Widget _thanhTuongTac() {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Row(
        children: [
          GestureDetector(
            onTap: _dangXuLyThich ? null : _toggleThich,
            child: Row(
              children: [
                Icon(
                  _daThich ? Icons.favorite : LucideIcons.heart,
                  color: _daThich ? Colors.red : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Text(
                  '$_soThich',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            onTap: widget.onComment,
            child: Row(
              children: [
                const Icon(
                  LucideIcons.messageCircle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Text(
                  '${widget.post.soLuotBinhLuan}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            onTap: widget.onShare,
            child: const Icon(
              LucideIcons.sendHorizontal,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
