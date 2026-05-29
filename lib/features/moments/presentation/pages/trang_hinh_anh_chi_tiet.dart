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
  final String? viTri;
  final String tenNguoiDang;
  final String thoiGian;

  const TrangHinhAnhChiTiet({
    super.key,
    this.duongDanAnh,
    this.viTri,
    this.tenNguoiDang = 'BongAnhHung',
    this.thoiGian = '3 tiếng trước',
  });

  @override
  State<TrangHinhAnhChiTiet> createState() =>
      _TrangHinhAnhChiTietState();
}

class _TrangHinhAnhChiTietState
    extends State<TrangHinhAnhChiTiet> {
  final TextEditingController _tinNhanController =
  TextEditingController();

  bool _hienMenuNguoiXem = false;

  bool _daThich = false;

  String get _anhDangXem {
    return widget.duongDanAnh ??
        'assets/images/anh1.jpg';
  }

  void _doiTrangThaiMenu() {
    setState(() {
      _hienMenuNguoiXem =
      !_hienMenuNguoiXem;
    });
  }

  void _tatMenu() {
    setState(() {
      _hienMenuNguoiXem = false;
    });
  }

  void _guiTinNhan() {
    final noiDung =
    _tinNhanController.text.trim();

    if (noiDung.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã gửi: $noiDung',
        ),
        backgroundColor:
        const Color(0xFF4AA8FF),
      ),
    );

    _tinNhanController.clear();
  }

  void _doiTrangThaiThich() {
    setState(() {
      _daThich = !_daThich;
    });
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

      bottomNavigationBar: const AppBottomNav(
        activeTab: MainTab.moments,
      ),

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
                    builder: (
                        context,
                        constraints,
                        ) {
                      final chieuCaoKhung =
                          constraints.maxHeight *
                              0.52;

                      final chieuCaoHopLy =
                      chieuCaoKhung.clamp(
                        270.0,
                        360.0,
                      );

                      return Column(
                        children: [
                          SizedBox(
                            height:
                            constraints.maxHeight *
                                0.04,
                          ),

                          _khungAnhLon(
                            chieuCaoHopLy,
                          ),

                          SizedBox(
                            height:
                            constraints.maxHeight *
                                0.02,
                          ),

                          _thongTinNguoiDang(),

                          const SizedBox(height: 14),

                          _oGuiTinNhan(),

                          const SizedBox(height: 16),

                          _thanhCongCuNoi(),

                          const Spacer(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            if (_hienMenuNguoiXem)
              _lopMenuNguoiXem(),
          ],
        ),
      ),
    );
  }

  Widget _khungAnhLon(double chieuCao) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        height: chieuCao,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius:
          BorderRadius.circular(30),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.25,
              ),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: _hienThiAnh(),
            ),

            Positioned(
              top: 14,
              right: 14,
              child: _nutYeuThich(),
            ),
            _thongTinViTri(),
          ],
        ),
      ),
    );
  }

  Widget _hienThiAnh() {
    if (_anhDangXem.startsWith('/') &&
        File(_anhDangXem).existsSync()) {
      return Image.file(
        File(_anhDangXem),
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      _anhDangXem,
      fit: BoxFit.cover,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return const Center(
          child: Text(
            'Ảnh',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }

  Widget _nutYeuThich() {
    return InkWell(
      onTap: _doiTrangThaiThich,
      borderRadius:
      BorderRadius.circular(20),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color:
          Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _daThich
              ? Icons.favorite
              : Icons.favorite_border,
          color: _daThich
              ? Colors.red
              : Colors.white,
          size: 23,
        ),
      ),
    );
  }

  Widget _thongTinNguoiDang() {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor:
          Color(0xFF4AA8FF),
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              widget.tenNguoiDang,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              widget.thoiGian,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _thongTinViTri() {
    if (widget.viTri == null ||
        widget.viTri!.trim().isEmpty) {
      return const SizedBox();
    }

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          height: 38,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          decoration: BoxDecoration(
            color:
            Colors.black.withOpacity(
              0.55,
            ),
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white24,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.mapPin,
                color: Colors.white,
                size: 18,
              ),

              const SizedBox(width: 7),

              Text(
                widget.viTri!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _oGuiTinNhan() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        height: 46,
        padding: const EdgeInsets.only(
          left: 18,
          right: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius:
          BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller:
                _tinNhanController,
                cursorColor: Colors.white,
                textInputAction:
                TextInputAction.send,
                onSubmitted: (_) =>
                    _guiTinNhan(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration:
                const InputDecoration(
                  border: InputBorder.none,
                  hintText:
                  'Gửi tin nhắn...',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),
            ),

            InkWell(
              onTap: _guiTinNhan,
              borderRadius:
              BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.send,
                  color: Color(0xFF4AA8FF),
                  size: 20,
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
        height: 46,
        width: 165,
        decoration: BoxDecoration(
          color:
          const Color(0xFF242424),
          borderRadius:
          BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,
          children: [
            _iconButton(
              icon: LucideIcons.grid2x2,
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.trangGalleryKhoanhKhac,
                        (route) => false,
                );
              },
            ),

            _iconButton(
              icon: LucideIcons.camera,
              onTap: () {
                Navigator
                    .pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.momentCamera,
                      (route) => false,
                );
              },
            ),

            _iconButton(
              icon: LucideIcons.download,
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã tải ảnh',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(20),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _lopMenuNguoiXem() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _tatMenu,
        child: Container(
          color:
          Colors.black.withOpacity(0.55),
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