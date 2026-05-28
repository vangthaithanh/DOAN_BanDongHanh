import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../widgets/menu_nguoi_xem.dart';
import '../widgets/thanh_tren_khoanhkhac.dart';

class TrangHinhAnhChiTiet extends StatefulWidget {
  final String? duongDanAnh;

  const TrangHinhAnhChiTiet({
    super.key,
    this.duongDanAnh,
  });

  @override
  State<TrangHinhAnhChiTiet> createState() => _TrangHinhAnhChiTietState();
}

class _TrangHinhAnhChiTietState extends State<TrangHinhAnhChiTiet> {
  final TextEditingController _tinNhanController = TextEditingController();

  bool _hienMenuNguoiXem = false;

  String get _anhDangXem {
    return widget.duongDanAnh ?? 'assets/images/anh1.jpg';
  }

  void _doiTrangThaiMenu() {
    setState(() {
      _hienMenuNguoiXem = !_hienMenuNguoiXem;
    });
  }

  void _tatMenu() {
    setState(() {
      _hienMenuNguoiXem = false;
    });
  }

  void _guiTinNhan() {
    final noiDung = _tinNhanController.text.trim();

    if (noiDung.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi tin nhắn demo'),
        backgroundColor: Color(0xFF4AA8FF),
      ),
    );

    _tinNhanController.clear();
  }

  @override
  void dispose() {
    _tinNhanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const AppBottomNav(activeTab: MainTab.moments),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const ThanhTrenKhoanhKhac(),

                NutChonNguoiXem(
                  onTap: _doiTrangThaiMenu,
                ),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final chieuCaoKhung = constraints.maxHeight * 0.52;
                      final chieuCaoHopLy = chieuCaoKhung.clamp(270.0, 340.0);

                      return Column(
                        children: [
                          SizedBox(height: constraints.maxHeight * 0.045),

                          _khungAnhLon(chieuCaoHopLy),

                          SizedBox(height: constraints.maxHeight * 0.018),

                          _thongTinNguoiDang(),

                          const SizedBox(height: 10),

                          _oGuiTinNhan(),

                          const SizedBox(height: 13),

                          _thanhCongCuNoi(),

                          const Spacer(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            if (_hienMenuNguoiXem) _lopMenuNguoiXem(),
          ],
        ),
      ),
    );
  }

  Widget _khungAnhLon(double chieuCao) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 31),
      child: Container(
        height: chieuCao,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(31),
        ),
        clipBehavior: Clip.antiAlias,
        child: _hienThiAnh(),
      ),
    );
  }

  Widget _hienThiAnh() {
    if (_anhDangXem.startsWith('/') && File(_anhDangXem).existsSync()) {
      return Image.file(
        File(_anhDangXem),
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      _anhDangXem,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Text(
            'Ảnh',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }

  Widget _thongTinNguoiDang() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: Color(0xFF4AA8FF),
        ),
        SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BongAnhHung',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 1),
            Text(
              '3 tiếng trước',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _oGuiTinNhan() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 31),
      child: Container(
        height: 31,
        padding: const EdgeInsets.only(left: 16, right: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tinNhanController,
                cursorColor: Colors.white,
                minLines: 1,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _guiTinNhan(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Gửi tin nhắn...',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 2),
                ),
              ),
            ),

            InkWell(
              onTap: _guiTinNhan,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  LucideIcons.smile,
                  color: Colors.white54,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thanhCongCuNoi() {
    return Center(
      child: Container(
        height: 34,
        width: 126,
        decoration: BoxDecoration(
          color: const Color(0xFF242424).withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _bieuTuongLuoi(
              onTap: () {},
            ),

            InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.momentCamera,
                      (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: const Color(0xFF4AA8FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),

            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 26,
                height: 26,
                child: Icon(
                  LucideIcons.download,
                  color: Colors.white70,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bieuTuongLuoi({
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 27,
        height: 27,
        child: Center(
          child: SizedBox(
            width: 17,
            height: 17,
            child: Wrap(
              spacing: 3,
              runSpacing: 3,
              children: List.generate(4, (index) {
                return Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 1.4),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lopMenuNguoiXem() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _tatMenu,
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Stack(
            children: const [
              Positioned(
                top: 84,
                left: 0,
                right: 0,
                child: Center(
                  child: MenuNguoiXem(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}