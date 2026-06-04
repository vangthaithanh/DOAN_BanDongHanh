import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  const PostCard({
    super.key,
    required this.post,
    this.onComment,
    this.onShare,
    this.onTap,
    this.onPostModified,
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
        if (updated != _timeText) setState(() => _timeText = updated);
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
                        },
                      ),
                    ),
                  );
                  if (result == true) widget.onPostModified?.call();
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

      widget.onPostModified?.call();
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
            // 1. Header: avatar + tên + thời gian + visibility + [...]
            _dongTieuDe(),

            // 2. Caption (tối đa 3 dòng + Xem thêm)
            if (widget.post.caption?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _captionWidget(),
            ],

            // 3. Hashtag
            if (widget.post.danhSachHashTag.isNotEmpty) ...[
              const SizedBox(height: 6),
              _hashTags(),
            ],

            // 4. Ảnh
            if (widget.post.danhSachAnh.isNotEmpty) ...[
              const SizedBox(height: 10),
              _danhSachAnh(),
            ],

            // 5. Reactions
            const SizedBox(height: 12),
            _thanhTuongTac(),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _dongTieuDe() {
    final avatarUrl = widget.post.anhDaiDienNguoiDang?.trim() ?? '';

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
              if (widget.post.viTri?.trim().isNotEmpty == true) ...[
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
                        widget.post.viTri!.trim(),
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
        if (widget.post.laBaiVietCuaToi)
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
        else
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
                  onTap: () => setState(() => _expandedCaption = true),
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
