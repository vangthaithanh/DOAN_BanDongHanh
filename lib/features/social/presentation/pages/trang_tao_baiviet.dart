import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../data/mock/kho_luu_bai_viet.dart';

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

  String? _duongDanAnh;
  String? _viTri;
  DoiTuongBaiViet _doiTuong = DoiTuongBaiViet.nguoiTheoDoi;
  final List<String> _danhSachHashTag = [];
  final List<String> _danhSachBanBe = [];

  @override
  void dispose() {
    _noiDungController.dispose();
    _focusNoiDung.dispose();
    super.dispose();
  }

  void _chiaSe() {
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

    KhoLuuBaiViet.instance.themBaiViet(
      duongDanAnh: _duongDanAnh,
      caption: noiDung.isNotEmpty ? noiDung : null,
      viTri: _viTri,
      danhSachHashTag: List.from(_danhSachHashTag),
      danhSachBanBe: List.from(_danhSachBanBe),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã chia sẻ bài viết!'),
        backgroundColor: Color(0xFF4AA8FF),
      ),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
          (route) => false,
    );
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

  void _themViTri() async {
    final ketQua = await Navigator.pushNamed(
      context,
      AppRoutes.trangViTri,
    );
    if (ketQua != null) {
      setState(() {
        _viTri = ketQua.toString();
      });
    }
  }

  void _chonDoiTuong() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetDoiTuong(
        doiTuongHienTai: _doiTuong,
        onChon: (dt) {
          setState(() => _doiTuong = dt);
          Navigator.pop(context);
        },
      ),
    );
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

  void _ganTheBanBe() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetBanBe(
        danhSachHienTai: _danhSachBanBe,
        onThem: (ten) {
          setState(() {
            if (!_danhSachBanBe.contains(ten)) {
              _danhSachBanBe.add(ten);
            }
          });
          Navigator.pop(context);
        },
      ),
    );
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

          const SizedBox(width: 12),

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

          // Spacer giả để title nằm giữa thật sự
          const SizedBox(
            width: 40,
            height: 40,
          ),
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
            Image.file(
              File(_duongDanAnh!),
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _moChonAnh,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
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
              children: _danhSachBanBe
                  .map((ten) => _chipBanBe(ten))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipHashTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _mauXanh.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _mauXanh.withOpacity(0.4)),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          color: _mauXanh,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _chipBanBe(String ten) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        '@$ten',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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

  Widget _dongTuyChon({
    required IconData icon,
    required String tieuDe,
    String? moTa,
    String? coGiaTriPhu,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
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
              child: Text(
                tieuDe,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (moTa != null || coGiaTriPhu != null) ...[
              Text(
                moTa ?? coGiaTriPhu ?? '',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
            ],
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
        onTap: _chiaSe,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _mauXanh,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: const Text(
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

// ─── Bottom sheet: Đối tượng ─────────────────────────────────────────────────

class _BottomSheetDoiTuong extends StatelessWidget {
  final DoiTuongBaiViet doiTuongHienTai;
  final ValueChanged<DoiTuongBaiViet> onChon;

  const _BottomSheetDoiTuong({
    required this.doiTuongHienTai,
    required this.onChon,
  });

  static const Color _mauXanh = Color(0xFF4AA8FF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đối tượng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ai có thể nhìn thấy bài viết của bạn',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _dongLuaChon(
            context,
            icon: LucideIcons.globe,
            tieuDe: 'Mọi người',
            moTa: null,
            gia: DoiTuongBaiViet.moiNguoi,
          ),
          _duongNgan(),
          _dongLuaChon(
            context,
            icon: LucideIcons.users,
            tieuDe: 'Người theo dõi',
            moTa: '100 người',
            gia: DoiTuongBaiViet.nguoiTheoDoi,
          ),
          _duongNgan(),
          _dongLuaChon(
            context,
            icon: LucideIcons.lock,
            tieuDe: 'Chỉ mình tôi',
            moTa: null,
            gia: DoiTuongBaiViet.chiMinhToi,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Lựa chọn này sẽ không khảo sát ảnh hưởng đến\nquyền riêng tư của tài khoản (đang ở chế\nđộ riêng tư)',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _duongNgan() =>
      const Divider(color: Color(0xFF2B2B2B), height: 1);

  Widget _dongLuaChon(
      BuildContext context, {
        required IconData icon,
        required String tieuDe,
        String? moTa,
        required DoiTuongBaiViet gia,
      }) {
    final laDuocChon = doiTuongHienTai == gia;
    return InkWell(
      onTap: () => onChon(gia),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tieuDe,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (moTa != null)
                    Text(
                      moTa,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: laDuocChon ? _mauXanh : Colors.white38,
                  width: 2,
                ),
                color: laDuocChon ? _mauXanh : Colors.transparent,
              ),
              child: laDuocChon
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
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
        .where((e) => (e['tag'] as String)
        .toLowerCase()
        .contains(_tuKhoa.toLowerCase()))
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
                    child: const Icon(Icons.close, color: Colors.white38, size: 18),
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
                separatorBuilder: (_, __) =>
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
                          horizontal: 16, vertical: 12),
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
                            const Icon(Icons.check,
                                color: Color(0xFF4AA8FF), size: 16),
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

// ─── Bottom sheet: Bạn bè ────────────────────────────────────────────────────

class _BottomSheetBanBe extends StatefulWidget {
  final List<String> danhSachHienTai;
  final ValueChanged<String> onThem;

  const _BottomSheetBanBe({
    required this.danhSachHienTai,
    required this.onThem,
  });

  @override
  State<_BottomSheetBanBe> createState() => _BottomSheetBanBeState();
}

class _BottomSheetBanBeState extends State<_BottomSheetBanBe> {
  static const Color _mauXanh = Color(0xFF4AA8FF);
  final TextEditingController _timKiemCtrl = TextEditingController();
  String _tuKhoa = '';

  static const List<Map<String, String>> _danhSachGoiY = [
    {'ten': 'thuwwww', 'hoten': 'Thu Thu'},
    {'ten': 'thuwwww', 'hoten': 'Thu Thu'},
    {'ten': 'BotDanh', 'hoten': 'Hồ Tên'},
  ];

  @override
  void dispose() {
    _timKiemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locDanhSach = _danhSachGoiY
        .where((b) =>
    _tuKhoa.isEmpty ||
        b['ten']!.toLowerCase().contains(_tuKhoa.toLowerCase()) ||
        b['hoten']!.toLowerCase().contains(_tuKhoa.toLowerCase()))
        .toList();

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
          const Text(
            'Chọn những người bạn muốn gắn thẻ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Những người mà bạn chọn sẽ không dùng\nnày để gắn thẻ nội dung bài viết và có\nquyền chế',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.danhSachHienTai.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.danhSachHienTai
                  .map((ten) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _mauXanh.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _mauXanh.withOpacity(0.4)),
                ),
                child: Text(
                  '@$ten',
                  style: const TextStyle(
                    color: _mauXanh,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search,
                    color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _timKiemCtrl,
                    autofocus: true,
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
          const SizedBox(height: 12),
          ...locDanhSach.map((banBe) {
            final daDuocChon = widget.danhSachHienTai.contains(banBe['ten']);
            return InkWell(
              onTap: () => widget.onThem(banBe['ten']!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _mauXanh.withOpacity(0.3),
                      child: Text(
                        banBe['ten']![0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banBe['ten']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            banBe['hoten']!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: daDuocChon ? _mauXanh : Colors.white38,
                          width: 2,
                        ),
                        color:
                        daDuocChon ? _mauXanh : Colors.transparent,
                      ),
                      child: daDuocChon
                          ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mauXanh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Thêm bạn bè',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}