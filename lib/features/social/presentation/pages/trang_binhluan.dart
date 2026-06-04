import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/models/binh_luan_model.dart';
import '../../data/models/post_model.dart';
import '../../data/services/post_service.dart';
import '../widgets/post_card.dart';

class TrangBinhLuan extends StatefulWidget {
  final int postId;

  const TrangBinhLuan({super.key, required this.postId});

  @override
  State<TrangBinhLuan> createState() => _TrangBinhLuanState();
}

class _TrangBinhLuanState extends State<TrangBinhLuan> {
  static const Color mauXanh = Color(0xFF4AA8FF);
  static const Color mauNen = Colors.black;
  static const Color mauVien = Color(0xFF2B2B2B);
  static const Color mauO = Color(0xFF3A3A3A);

  final TextEditingController _binhLuanController = TextEditingController();
  final FocusNode _focusBinhLuan = FocusNode();
  final PostService _postService = PostService();

  PostModel? _post;
  List<BinhLuanModel> _danhSachBinhLuan = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _binhLuanController.dispose();
    _focusBinhLuan.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final post = await _postService.loadPostById(widget.postId);
      final comments = await _postService.loadComments(widget.postId);

      if (!mounted) {
        return;
      }

      setState(() {
        _post = post;
        _danhSachBinhLuan = comments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _themBinhLuan() async {
    if (_sending) {
      return;
    }

    final noiDung = _binhLuanController.text.trim();

    if (noiDung.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final comment = await _postService.addComment(
        postId: widget.postId,
        content: noiDung,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _danhSachBinhLuan.insert(0, comment);
        _binhLuanController.clear();
        _post = _post?.copyWith(
          soLuotBinhLuan: (_post?.soLuotBinhLuan ?? 0) + 1,
        );
        _sending = false;
        _changed = true;
      });

      _focusBinhLuan.unfocus();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _quayLai() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, _changed);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mauNen,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _thanhTren(context),

            Expanded(child: _noiDungTrang()),

            if (!_loading && _error == null) _oNhapBinhLuan(),

            const Divider(color: mauVien, height: 1, thickness: 1),

            _thanhDieuHuongDuoi(context),
          ],
        ),
      ),
    );
  }

  Widget _noiDungTrang() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 14),
              TextButton(onPressed: _loadData, child: const Text('Tải lại')),
            ],
          ),
        ),
      );
    }

    final post = _post;

    if (post == null) {
      return _khongCoBinhLuan();
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostCard(
            post: post,
            onComment: () {},
            onShare: () {
              Navigator.pushNamed(context, AppRoutes.messages);
            },
            onPostModified: () async {
              _changed = true;
              final updated = await _postService.loadPostById(widget.postId);

              if (!mounted) {
                return;
              }

              setState(() {
                _post = updated;
              });
            },
          ),
          const Divider(color: mauVien, height: 1, thickness: 1),
          _sapXepBinhLuan(),
          if (_danhSachBinhLuan.isEmpty)
            _khongCoBinhLuan()
          else
            Padding(
              padding: const EdgeInsets.only(left: 26, right: 22),
              child: Column(
                children: _danhSachBinhLuan.map((binhLuan) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _BinhLuanCha(binhLuan: binhLuan),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _thanhTren(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 28,
            top: 18,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _quayLai,
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E2E31),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          Positioned(
            top: 24,
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Go',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: 'Mate',
                    style: TextStyle(
                      color: Color(0xFF4AA8FF),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            right: 34,
            top: 27,
            child: Icon(LucideIcons.bell, color: Colors.white, size: 27),
          ),
        ],
      ),
    );
  }

  Widget _sapXepBinhLuan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 8, 24, 8),
      child: Row(
        children: const [
          Text(
            'Mới nhất',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 3),
          Icon(LucideIcons.chevronDown, color: Colors.white, size: 17),
        ],
      ),
    );
  }

  Widget _khongCoBinhLuan() {
    return const Padding(
      padding: EdgeInsets.only(top: 28),
      child: Text(
        'Chưa có bình luận nào',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white54,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _oNhapBinhLuan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 8, 30, 20),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: mauO,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),

            const Icon(LucideIcons.camera, color: Colors.white, size: 21),

            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                controller: _binhLuanController,
                focusNode: _focusBinhLuan,
                cursorColor: Colors.white,
                minLines: 1,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _themBinhLuan(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Bình luận',
                  hintStyle: TextStyle(
                    color: Colors.white60,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 2),
                ),
              ),
            ),

            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _sending
                  ? null
                  : () {
                      _themBinhLuan();
                    },
              child: SizedBox(
                width: 32,
                height: 34,
                child: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        LucideIcons.sendHorizontal,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),

            const SizedBox(width: 4),

            const Icon(LucideIcons.image, color: Colors.white, size: 21),

            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _thanhDieuHuongDuoi(BuildContext context) {
    return SizedBox(
      height: 61,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _iconNav(
            icon: LucideIcons.house,
            mau: mauXanh,
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
          ),
          _iconNav(
            icon: LucideIcons.aperture,
            mau: Colors.white,
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.momentCamera,
                (route) => false,
              );
            },
          ),
          _iconNav(
            icon: LucideIcons.mapPin,
            mau: Colors.white,
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.map,
                (route) => false,
              );
            },
          ),
          _iconNav(
            icon: LucideIcons.messagesSquare,
            mau: Colors.white,
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.messages,
                (route) => false,
              );
            },
          ),
          _iconNav(
            icon: LucideIcons.userRound,
            mau: Colors.white,
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.profile,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _iconNav({
    required IconData icon,
    required Color mau,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon, color: mau, size: 26),
      ),
    );
  }
}

class _BinhLuanCha extends StatelessWidget {
  final BinhLuanModel binhLuan;

  const _BinhLuanCha({required this.binhLuan});

  static const Color mauXanh = Color(0xFF4AA8FF);

  @override
  Widget build(BuildContext context) {
    final coTraLoi = binhLuan.danhSachTraLoi.isNotEmpty;

    return Stack(
      children: [
        if (coTraLoi)
          Positioned(
            left: 17,
            top: 38,
            height: 42,
            child: Container(width: 1, color: Colors.white24),
          ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _noiDungBinhLuan(binhLuan),

            ...binhLuan.danhSachTraLoi.map((traLoi) {
              return Padding(
                padding: const EdgeInsets.only(left: 17, top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 1,
                      margin: const EdgeInsets.only(top: 17),
                      color: Colors.white24,
                    ),
                    _noiDungTraLoi(traLoi),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _noiDungBinhLuan(BinhLuanModel binhLuan) {
    final avatarUrl = binhLuan.anhDaiDienNguoiBinhLuan?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: mauXanh,
          backgroundImage: avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? Text(
                  binhLuan.tenNguoiBinhLuan.isEmpty
                      ? '?'
                      : binhLuan.tenNguoiBinhLuan[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _cotNoiDungBinhLuan(binhLuan: binhLuan, laTraLoi: false),
        ),
      ],
    );
  }

  Widget _noiDungTraLoi(BinhLuanModel binhLuan) {
    final avatarUrl = binhLuan.anhDaiDienNguoiBinhLuan?.trim() ?? '';

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: mauXanh,
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    binhLuan.tenNguoiBinhLuan.isEmpty
                        ? '?'
                        : binhLuan.tenNguoiBinhLuan[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _cotNoiDungBinhLuan(binhLuan: binhLuan, laTraLoi: true),
          ),
        ],
      ),
    );
  }

  Widget _cotNoiDungBinhLuan({
    required BinhLuanModel binhLuan,
    required bool laTraLoi,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 1),

        if (laTraLoi && binhLuan.tenNguoiDuocTraLoi != null)
          _dongTenTraLoi(binhLuan)
        else
          _dongTenBinhLuan(binhLuan),

        const SizedBox(height: 7),

        Text(
          binhLuan.noiDung,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 9),

        const Text(
          'Trả lời',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _dongTenBinhLuan(BinhLuanModel binhLuan) {
    return Row(
      children: [
        Flexible(
          child: Text(
            binhLuan.tenNguoiBinhLuan,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          binhLuan.thoiGian,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _dongTenTraLoi(BinhLuanModel binhLuan) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${binhLuan.tenNguoiBinhLuan} ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(
            text: 'đến ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '${binhLuan.tenNguoiDuocTraLoi}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: '  ${binhLuan.thoiGian}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
