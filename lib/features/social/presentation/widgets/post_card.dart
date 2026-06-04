import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/post_model.dart';
import '../../data/services/post_service.dart';

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

  @override
  void initState() {
    super.initState();
    _soThich = widget.post.soLuotThich;
    _daThich = widget.post.daThich;
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
              _caption(),
            ],
            if (widget.post.viTri != null) ...[
              const SizedBox(height: 6),
              _viTri(),
            ],
            if (widget.post.danhSachHashTag.isNotEmpty) ...[
              const SizedBox(height: 6),
              _hashTags(),
            ],
            if (widget.post.danhSachAnh.isNotEmpty) ...[
              const SizedBox(height: 10),
              _danhSachAnh(),
            ],
            const SizedBox(height: 12),
            _thanhTuongTac(),
          ],
        ),
      ),
    );
  }

  Widget _dongTieuDe() {
    final avatarUrl = widget.post.anhDaiDienNguoiDang?.trim() ?? '';

    return Row(
      children: [
        CircleAvatar(
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.tenNguoiDang,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                widget.post.thoiGian,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Icon(LucideIcons.ellipsis, color: Colors.white54, size: 20),
      ],
    );
  }

  Widget _caption() {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Text(
        widget.post.caption!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _viTri() {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Row(
        children: [
          const Icon(LucideIcons.mapPin, color: _mauXanh, size: 13),
          const SizedBox(width: 4),
          Text(
            widget.post.viTri!,
            style: const TextStyle(
              color: _mauXanh,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
      return Padding(
        padding: const EdgeInsets.only(left: 50),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 240,
            child: _hienThiAnh(danhSach[0]),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 50, right: 12),
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
            onTap: _dangXuLyThich
                ? null
                : () {
                    _toggleThich();
                  },
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
