import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/services/post_service.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

enum DoiTuongBaiViet { moiNguoi, nguoiTheoDoi, chiMinhToi }

// ─── Page ────────────────────────────────────────────────────────────────────

class TrangTaoBaiViet extends StatefulWidget {
  const TrangTaoBaiViet({super.key});

  @override
  State<TrangTaoBaiViet> createState() => _TrangTaoBaiVietState();
}

class _TrangTaoBaiVietState extends State<TrangTaoBaiViet> {
  static const Color _mauXanh = Color(0xFF4AA8FF);
  static const Color _mauNen = Colors.black;
  static const Color _mauVien = Color(0xFF2B2B2B);
  static const Color _mauO = Color(0xFF1C1C1E);

  final TextEditingController _noiDungController = TextEditingController();
  final FocusNode _focusNoiDung = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final PostService _postService = PostService();

  String? _duongDanAnh;
  String? _viTri;
  DoiTuongBaiViet _doiTuong = DoiTuongBaiViet.moiNguoi;
  final List<String> _danhSachHashTag = [];
  final List<String> _danhSachBanBe = [];
  bool _dangChiaSe = false;

  @override
  void dispose() {
    _noiDungController.dispose();
    _focusNoiDung.dispose();
    super.dispose();
  }

  Future<void> _chiaSe() async {
    if (_dangChiaSe) {
      return;
    }

    final noiDung = _noiDungController.text.trim();

    if (_duongDanAnh == null && noiDung.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ảnh hoặc nội dung'),
          backgroundColor: Color(0xFF4AA8FF),
        ),
      );
      return;
    }

    setState(() {
      _dangChiaSe = true;
    });

    try {
      await _postService.createPost(
        content: noiDung,
        visibility: _visibilityValue,
        imagePath: _duongDanAnh,
        locationName: _viTri,
        hashtags: List.from(_danhSachHashTag),
        taggedNicknames: List.from(_danhSachBanBe),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chia sẻ bài viết!'),
          backgroundColor: Color(0xFF4AA8FF),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _dangChiaSe = false;
        });
      }
    }
  }

  void _moChonAnh() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
            const SizedBox(height: 20),
            _dongChonNguonAnh(
              icon: LucideIcons.camera,
              tieuDe: 'Mở camera',
              onTap: () async {
                Navigator.pop(context);
                final xFile = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (xFile != null) {
                  setState(() => _duongDanAnh = xFile.path);
                }
              },
            ),
            const Divider(color: Color(0xFF2B2B2B), height: 1),
            _dongChonNguonAnh(
              icon: LucideIcons.image,
              tieuDe: 'Chọn từ thư viện',
              onTap: () async {
                Navigator.pop(context);
                final xFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (xFile != null) {
                  setState(() => _duongDanAnh = xFile.path);
                }
              },
            ),
            if (_duongDanAnh != null) ...[
              const Divider(color: Color(0xFF2B2B2B), height: 1),
              _dongChonNguonAnh(
                icon: LucideIcons.trash2,
                tieuDe: 'Xoá ảnh',
                mauIcon: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _duongDanAnh = null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dongChonNguonAnh({
    required IconData icon,
    required String tieuDe,
    required VoidCallback onTap,
    Color mauIcon = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2B2B2B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: mauIcon, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              tieuDe,
              style: TextStyle(
                color: mauIcon == Colors.white ? Colors.white : mauIcon,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NOTE SỬA:
  // TrangViTri hiện trả về Map:
  // {
  //   'nearby_place_name': địa chỉ,
  //   'latitude': ...,
  //   'longitude': ...
  // }
  // Không được dùng ketQua.toString() vì sẽ bị hiện:
  // {nearby_place_name: 26B Đ. số 8, latitude: ...}
  String? _layTenViTriTuKetQua(dynamic ketQua) {
    if (ketQua == null) return null;

    if (ketQua is Map) {
      final value =
          ketQua['nearby_place_name'] ??
          ketQua['locationName'] ??
          ketQua['viTri'] ??
          ketQua['address'] ??
          ketQua['dia_chi'];

      final text = value?.toString().trim();

      if (text == null || text.isEmpty || text == 'null') {
        return null;
      }

      return text;
    }

    final text = ketQua.toString().trim();

    if (text.isEmpty || text == 'null') return null;

    // NOTE SỬA:
    // Chữa luôn dữ liệu/string cũ dạng:
    // {nearby_place_name: 26B Đ. số 8, Thành phố Hồ Chí Minh, latitude: 10...}
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

  void _themViTri() async {
    final ketQua = await Navigator.pushNamed(context, AppRoutes.trangViTri);

    final tenViTri = _layTenViTriTuKetQua(ketQua);

    if (tenViTri == null) return;

    setState(() {
      _viTri = tenViTri;
    });
  }

  void _chonDoiTuong() async {
    final ketQua = await Navigator.push<DoiTuongBaiViet>(
      context,
      MaterialPageRoute(
        builder: (_) => TrangDoiTuongBaiViet(doiTuongHienTai: _doiTuong),
      ),
    );
    if (ketQua != null) {
      setState(() => _doiTuong = ketQua);
    }
  }

  void _themHashTag() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetHashTag(
        danhSachHienTai: _danhSachHashTag,
        onThem: (tag) {
          setState(() {
            if (!_danhSachHashTag.contains(tag)) {
              _danhSachHashTag.add(tag);
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _ganTheBanBe() async {
    final ketQua = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrangGanTheBanBe(danhSachDaChon: List.from(_danhSachBanBe)),
      ),
    );
    if (ketQua != null) {
      setState(() {
        _danhSachBanBe
          ..clear()
          ..addAll(ketQua);
      });
    }
  }

  String get _tenDoiTuong {
    switch (_doiTuong) {
      case DoiTuongBaiViet.moiNguoi:
        return 'Mọi người';
      case DoiTuongBaiViet.nguoiTheoDoi:
        return 'Người theo dõi';
      case DoiTuongBaiViet.chiMinhToi:
        return 'Chỉ mình tôi';
    }
  }

  String get _visibilityValue {
    switch (_doiTuong) {
      case DoiTuongBaiViet.moiNguoi:
        return 'public';
      case DoiTuongBaiViet.nguoiTheoDoi:
        return 'follower';
      case DoiTuongBaiViet.chiMinhToi:
        return 'private';
    }
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
                    _khuVucAnh(),
                    _khuVucNhapLieu(),
                    const Divider(color: _mauVien, height: 1),
                    _danhSachTuyChon(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _nutChiaSe(),
          ],
        ),
      ),
    );
  }

  // ── Thanh trên ─────────────────────────────────────────────────────────────

  Widget _thanhTren() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                );
              }
            },
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
              'Bài viết mới',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Placeholder giữ title căn giữa đúng
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Khu vực ảnh ────────────────────────────────────────────────────────────

  Widget _khuVucAnh() {
    return GestureDetector(
      onTap: _moChonAnh,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        height: 220,
        decoration: BoxDecoration(
          color: _mauO,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _mauVien),
        ),
        clipBehavior: Clip.antiAlias,
        child: _duongDanAnh == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2B2B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.imagePlus,
                      color: Colors.white54,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thêm ảnh',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Camera hoặc thư viện',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(_duongDanAnh!), fit: BoxFit.cover),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _moChonAnh,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.pencil,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Khu vực nhập liệu ──────────────────────────────────────────────────────

  Widget _khuVucNhapLieu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _noiDungController,
            focusNode: _focusNoiDung,
            cursorColor: Colors.white,
            maxLines: null,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Thêm chú thích...',
              hintStyle: TextStyle(
                color: Colors.white38,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (_danhSachHashTag.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _danhSachHashTag
                  .map((tag) => _chipHashTag(tag))
                  .toList(),
            ),
          ],
          if (_danhSachBanBe.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _danhSachBanBe.map((ten) => _chipBanBe(ten)).toList(),
            ),
          ],
        ],
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
            onTap: () => setState(() => _danhSachHashTag.remove(tag)),
            child: const Icon(Icons.close, color: _mauXanh, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _chipBanBe(String ten) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '@$ten',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _danhSachBanBe.remove(ten)),
            child: const Icon(Icons.close, color: Colors.white54, size: 14),
          ),
        ],
      ),
    );
  }

  // ── Danh sách tuỳ chọn ─────────────────────────────────────────────────────

  Widget _danhSachTuyChon() {
    return Column(
      children: [
        _dongTuyChon(
          icon: LucideIcons.hash,
          tieuDe: '#NhapHash...',
          moTa: null,
          onTap: _themHashTag,
          coGiaTriPhu: _danhSachHashTag.isNotEmpty
              ? '${_danhSachHashTag.length} tag'
              : null,
        ),
        _duongNgan(),
        _dongTuyChon(
          icon: LucideIcons.userRoundPlus,
          tieuDe: 'Gắn thẻ người khác',
          moTa: null,
          onTap: _ganTheBanBe,
          coGiaTriPhu: _danhSachBanBe.isNotEmpty
              ? '${_danhSachBanBe.length} người'
              : null,
        ),
        _duongNgan(),
        _dongTuyChon(
          icon: LucideIcons.mapPin,
          tieuDe: 'Thêm vị trí',
          moTa: _viTri,
          onTap: _themViTri,
        ),
        _duongNgan(),
        _dongTuyChon(
          icon: LucideIcons.users,
          tieuDe: 'Đối tượng',
          moTa: _tenDoiTuong,
          onTap: _chonDoiTuong,
        ),
      ],
    );
  }

  Widget _duongNgan() =>
      const Divider(color: Color(0xFF1E1E1E), height: 1, indent: 56);

  // NOTE SỬA:
  // Sửa layout dòng tuỳ chọn để mô tả dài như địa chỉ GPS
  // không làm chữ "Thêm vị trí" bị bóp xuống từng ký tự.
  Widget _dongTuyChon({
    required IconData icon,
    required String tieuDe,
    String? moTa,
    String? coGiaTriPhu,
    required VoidCallback onTap,
  }) {
    final String? phu = moTa ?? coGiaTriPhu;
    final bool coMoTa = phu != null && phu.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white70, size: 18),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tieuDe,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (coMoTa) ...[
                    const SizedBox(height: 4),
                    Text(
                      phu.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Nút chia sẻ ────────────────────────────────────────────────────────────

  Widget _nutChiaSe() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: _dangChiaSe ? null : _chiaSe,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _dangChiaSe ? _mauXanh.withValues(alpha: 0.65) : _mauXanh,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: _dangChiaSe
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Chia sẻ →',
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

// ─── Trang Đối Tượng ─────────────────────────────────────────────────────────

class TrangDoiTuongBaiViet extends StatefulWidget {
  final DoiTuongBaiViet doiTuongHienTai;

  const TrangDoiTuongBaiViet({super.key, required this.doiTuongHienTai});

  @override
  State<TrangDoiTuongBaiViet> createState() => _TrangDoiTuongBaiVietState();
}

class _TrangDoiTuongBaiVietState extends State<TrangDoiTuongBaiViet> {
  static const Color _mauXanh = Color(0xFF4AA8FF);
  late DoiTuongBaiViet _duocChon;
  int? _followerCount;

  @override
  void initState() {
    super.initState();
    _duocChon = widget.doiTuongHienTai;
    _loadFollowerCount();
  }

  Future<void> _loadFollowerCount() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final rows = await client
          .from('follows')
          .select('id')
          .eq('following_id', user.id)
          .eq('status', 'active');
      if (!mounted) return;
      setState(() => _followerCount = (rows as List).length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh trên
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _duocChon),
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
                      'Đối tượng',
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
            ),

            const SizedBox(height: 16),

            // Mô tả
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Ai có thể nhìn thấy chú thích của bạn',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Danh sách lựa chọn
            _dongLuaChon(
              icon: LucideIcons.globe,
              tieuDe: 'Mọi người',
              moTa: null,
              gia: DoiTuongBaiViet.moiNguoi,
            ),
            const Divider(color: Color(0xFF1E1E1E), height: 1, indent: 24),
            _dongLuaChon(
              icon: LucideIcons.userRound,
              tieuDe: 'Người theo dõi',
              moTa: _followerCount != null ? '${_followerCount} người theo dõi' : null,
              gia: DoiTuongBaiViet.nguoiTheoDoi,
            ),
            const Divider(color: Color(0xFF1E1E1E), height: 1, indent: 24),
            _dongLuaChon(
              icon: LucideIcons.eye,
              tieuDe: 'Chỉ mình tôi',
              moTa: null,
              gia: DoiTuongBaiViet.chiMinhToi,
            ),

            const SizedBox(height: 24),

            // Ghi chú
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Lựa chọn này sẽ không ảnh hưởng đến\nquyền riêng tư của tài khoản (đang ở chế\nđộ riêng tư)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dongLuaChon({
    required IconData icon,
    required String tieuDe,
    String? moTa,
    required DoiTuongBaiViet gia,
  }) {
    final laDuocChon = _duocChon == gia;
    return InkWell(
      onTap: () {
        setState(() => _duocChon = gia);
        final navigator = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) {
            return;
          }

          navigator.pop(gia);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tieuDe,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (moTa != null)
                    Text(
                      moTa,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Radio circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: laDuocChon ? _mauXanh : Colors.white38,
                  width: 2,
                ),
                color: laDuocChon ? _mauXanh : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom sheet: HashTag ────────────────────────────────────────────────────

class _BottomSheetHashTag extends StatefulWidget {
  final List<String> danhSachHienTai;
  final ValueChanged<String> onThem;

  const _BottomSheetHashTag({
    required this.danhSachHienTai,
    required this.onThem,
  });

  @override
  State<_BottomSheetHashTag> createState() => _BottomSheetHashTagState();
}

class _BottomSheetHashTagState extends State<_BottomSheetHashTag> {
  final TextEditingController _ctrl = TextEditingController();
  String _tuKhoa = '';

  static const List<Map<String, dynamic>> _tatCaGoiY = [
    {'tag': 'NhapHashTag', 'luot': '1,2k'},
    {'tag': 'GoMate', 'luot': '1,2k'},
    {'tag': 'DuLich', 'luot': '980'},
    {'tag': 'AmThuc', 'luot': '750'},
    {'tag': 'SaiGon', 'luot': '2,1k'},
    {'tag': 'HaNoi', 'luot': '1,8k'},
    {'tag': 'CaPhe', 'luot': '430'},
    {'tag': 'CheckIn', 'luot': '3,4k'},
  ];

  List<Map<String, dynamic>> get _goiYLocDuoc {
    if (_tuKhoa.isEmpty) return _tatCaGoiY;
    return _tatCaGoiY
        .where(
          (e) => (e['tag'] as String).toLowerCase().contains(
            _tuKhoa.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                    color: Color(0xFF4AA8FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
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
                    onChanged: (val) => setState(() => _tuKhoa = val),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) widget.onThem(val.trim());
                    },
                  ),
                ),
                if (_tuKhoa.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _ctrl.clear();
                      setState(() => _tuKhoa = '');
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_goiYLocDuoc.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2B2B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: _goiYLocDuoc.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Color(0xFF3A3A3A), height: 1),
                itemBuilder: (context, index) {
                  final item = _goiYLocDuoc[index];
                  final tag = item['tag'] as String;
                  final luot = item['luot'] as String;
                  final daDuocChon = widget.danhSachHienTai.contains(tag);
                  return InkWell(
                    onTap: () => widget.onThem(tag),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                color: daDuocChon
                                    ? const Color(0xFF4AA8FF)
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            luot,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (daDuocChon) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check,
                              color: Color(0xFF4AA8FF),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Trang Gắn Thẻ Bạn Bè ────────────────────────────────────────────────────

class _TagFriend {
  final String id;
  final String nickname;
  final String fullName;
  final String? avatarUrl;
  const _TagFriend({
    required this.id,
    required this.nickname,
    required this.fullName,
    this.avatarUrl,
  });
}

class TrangGanTheBanBe extends StatefulWidget {
  final List<String> danhSachDaChon;

  const TrangGanTheBanBe({super.key, required this.danhSachDaChon});

  @override
  State<TrangGanTheBanBe> createState() => _TrangGanTheBanBeState();
}

class _TrangGanTheBanBeState extends State<TrangGanTheBanBe> {
  static const Color _mauXanh = Color(0xFF4AA8FF);

  List<_TagFriend> _allFriends = [];
  bool _loading = true;

  final TextEditingController _timKiemCtrl = TextEditingController();
  String _tuKhoa = '';
  late List<String> _danhSachDaChon;

  @override
  void initState() {
    super.initState();
    _danhSachDaChon = List.from(widget.danhSachDaChon);
    _loadFriends();
  }

  @override
  void dispose() {
    _timKiemCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final followingRows = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', user.id)
          .eq('status', 'active');
      final followingIds = (followingRows as List)
          .map((r) => (r as Map)['following_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      if (followingIds.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final mutualRows = await client
          .from('follows')
          .select('follower_id')
          .inFilter('follower_id', followingIds)
          .eq('following_id', user.id)
          .eq('status', 'active');
      final mutualIds = (mutualRows as List)
          .map((r) => (r as Map)['follower_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (mutualIds.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final profileRows = await client
          .from('profiles')
          .select('id, nickname, full_name, avatar_url')
          .inFilter('id', mutualIds);
      final friends = (profileRows as List).map((p) {
        final m = p as Map<String, dynamic>;
        return _TagFriend(
          id: m['id']?.toString() ?? '',
          nickname: m['nickname']?.toString() ?? 'Người dùng',
          fullName: m['full_name']?.toString() ?? '',
          avatarUrl: m['avatar_url']?.toString(),
        );
      }).where((f) => f.id.isNotEmpty).toList();
      friends.sort((a, b) => a.nickname.compareTo(b.nickname));
      if (!mounted) return;
      setState(() {
        _allFriends = friends;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_TagFriend> get _locDanhSach {
    if (_tuKhoa.isEmpty) return _allFriends;
    return _allFriends
        .where((f) =>
            f.nickname.toLowerCase().contains(_tuKhoa.toLowerCase()) ||
            f.fullName.toLowerCase().contains(_tuKhoa.toLowerCase()))
        .toList();
  }

  void _toggleChon(String ten) {
    setState(() {
      if (_danhSachDaChon.contains(ten)) {
        _danhSachDaChon.remove(ten);
      } else {
        _danhSachDaChon.add(ten);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh trên
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _danhSachDaChon),
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
                      'Bạn bè',
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
            ),

            // Tiêu đề + mô tả
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Chọn những người bạn muốn gắn thẻ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Những người mà bạn chia sẻ nội dung này\ncó thể nhìn thấy nội dung bài viết và có\nquyền gỡ thẻ',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Avatar đã chọn
            if (_danhSachDaChon.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: _danhSachDaChon.map((ten) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _mauXanh,
                              child: Text(
                                ten[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: GestureDetector(
                                onTap: () => _toggleChon(ten),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3A3A3A),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ten,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

            // Ô tìm kiếm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2B2B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      color: Colors.white38,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _timKiemCtrl,
                        cursorColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Tìm Kiếm',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        onChanged: (val) => setState(() => _tuKhoa = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Danh sách bạn bè
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _mauXanh))
                  : _allFriends.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Không có bạn bè nào',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: _locDanhSach.length,
                itemBuilder: (context, index) {
                  final f = _locDanhSach[index];
                  final daDuocChon = _danhSachDaChon.contains(f.nickname);
                  final hasAvatar = f.avatarUrl?.trim().isNotEmpty == true;
                  return InkWell(
                    onTap: () => _toggleChon(f.nickname),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _mauXanh,
                            backgroundImage: hasAvatar ? NetworkImage(f.avatarUrl!) : null,
                            child: hasAvatar
                                ? null
                                : Text(
                                    f.nickname.isEmpty ? '?' : f.nickname[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.nickname,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (f.fullName.isNotEmpty)
                                  Text(
                                    f.fullName,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: daDuocChon ? _mauXanh : Colors.transparent,
                              border: Border.all(
                                color: daDuocChon ? _mauXanh : Colors.white38,
                                width: 2,
                              ),
                            ),
                            child: daDuocChon
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Divider + nút Thêm bạn bè
            const Divider(color: Color(0xFF2B2B2B), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context, _danhSachDaChon),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _mauXanh,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Thêm bạn bè',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
