import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/post_service.dart';

enum _Visibility { moiNguoi, nguoiTheoDoi, chiMinhToi }

extension _VisibilityX on _Visibility {
  String get label {
    switch (this) {
      case _Visibility.moiNguoi:
        return 'Mọi người';
      case _Visibility.nguoiTheoDoi:
        return 'Người theo dõi';
      case _Visibility.chiMinhToi:
        return 'Chỉ mình tôi';
    }
  }

  String get value {
    switch (this) {
      case _Visibility.moiNguoi:
        return 'public';
      case _Visibility.nguoiTheoDoi:
        return 'follower';
      case _Visibility.chiMinhToi:
        return 'private';
    }
  }

  static _Visibility fromValue(String v) {
    switch (v) {
      case 'follower':
        return _Visibility.nguoiTheoDoi;
      case 'private':
        return _Visibility.chiMinhToi;
      default:
        return _Visibility.moiNguoi;
    }
  }
}

class TrangChinhSuaBaiViet extends StatefulWidget {
  final int postId;
  final String? initialContent;
  final List<String> initialHashtags;

  const TrangChinhSuaBaiViet({
    super.key,
    required this.postId,
    this.initialContent,
    this.initialHashtags = const [],
  });

  @override
  State<TrangChinhSuaBaiViet> createState() => _TrangChinhSuaBaiVietState();
}

class _TrangChinhSuaBaiVietState extends State<TrangChinhSuaBaiViet> {
  static const Color _mauXanh = Color(0xFF4AA8FF);
  static const Color _mauNen = Colors.black;
  static const Color _mauVien = Color(0xFF2B2B2B);
  static const Color _mauO = Color(0xFF1C1C1E);

  late TextEditingController _contentController;
  late List<String> _hashtags;
  _Visibility _visibility = _Visibility.moiNguoi;

  bool _loadingVisibility = true;
  bool _saving = false;

  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
    _hashtags = List<String>.from(widget.initialHashtags);
    _loadVisibility();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadVisibility() async {
    try {
      final row = await Supabase.instance.client
          .from('posts')
          .select('visibility')
          .eq('id', widget.postId)
          .single();
      if (mounted) {
        setState(() {
          _visibility = _VisibilityX.fromValue(
            row['visibility']?.toString() ?? 'public',
          );
          _loadingVisibility = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVisibility = false);
    }
  }

  Future<void> _luu() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await _postService.updatePost(
        postId: widget.postId,
        content: _contentController.text,
        visibility: _visibility.value,
        hashtags: _hashtags,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật bài viết!'),
          backgroundColor: _mauXanh,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _chonDoiTuong() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _mauO,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ai có thể xem bài viết này?',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in _Visibility.values) ...[
              InkWell(
                onTap: () {
                  setState(() => _visibility = option);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: _visibility == option
                                ? _mauXanh
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_visibility == option)
                        const Icon(Icons.check, color: _mauXanh, size: 20),
                    ],
                  ),
                ),
              ),
              if (option != _Visibility.chiMinhToi)
                const Divider(color: Color(0xFF2B2B2B), height: 1),
            ],
          ],
        ),
      ),
    );
  }

  void _themHashTag() {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: _mauO,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2B2B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    '#',
                    style: TextStyle(
                      color: _mauXanh,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      autofocus: true,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Nhập hashtag...',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                      onSubmitted: (val) {
                        final tag = val.trim();
                        if (tag.isNotEmpty && !_hashtags.contains(tag)) {
                          setState(() => _hashtags.add(tag));
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mauNen,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _thanhTren(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _khuVucNoiDung(),
                    const Divider(color: _mauVien, height: 1),
                    _khuVucHashTag(),
                    const Divider(color: _mauVien, height: 1),
                    _khuVucDoiTuong(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _nutLuu(),
          ],
        ),
      ),
    );
  }

  Widget _thanhTren() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF2E2E31),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Chỉnh sửa bài viết',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _khuVucNoiDung() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội dung',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            cursorColor: Colors.white,
            maxLines: null,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Nội dung bài viết...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _khuVucHashTag() {
    return InkWell(
      onTap: _themHashTag,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _mauO,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.hash,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  _hashtags.isEmpty
                      ? 'Thêm hashtag'
                      : '${_hashtags.length} hashtag',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Colors.white38,
                  size: 18,
                ),
              ],
            ),
            if (_hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _hashtags.map((tag) => _chipHashTag(tag)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chipHashTag(String tag) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: _mauXanh.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _mauXanh.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: const TextStyle(
              color: _mauXanh,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _hashtags.remove(tag)),
            child: const Icon(Icons.close, color: _mauXanh, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _khuVucDoiTuong() {
    return InkWell(
      onTap: _loadingVisibility ? null : _chonDoiTuong,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _mauO,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.users,
                color: Colors.white70,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              _loadingVisibility ? 'Đang tải...' : _visibility.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _nutLuu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: _saving ? null : _luu,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _saving
                ? _mauXanh.withValues(alpha: 0.6)
                : _mauXanh,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: _saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}