import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../data/mock/mock_khoanhkhac.dart';
import '../widgets/menu_nguoi_xem.dart';
import '../widgets/thanh_tren_khoanhkhac.dart';

class TrangGalleryKhoanhKhac extends StatefulWidget {
  const TrangGalleryKhoanhKhac({super.key});

  @override
  State<TrangGalleryKhoanhKhac> createState() => _TrangGalleryKhoanhKhacState();
}

class _TrangGalleryKhoanhKhacState extends State<TrangGalleryKhoanhKhac> {
  bool _hienMenuNguoiXem = false;

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

  @override
  Widget build(BuildContext context) {
    final danhSach = layDanhSachKhoanhKhacHienThi();

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

                const SizedBox(height: 16),

                Expanded(
                  child: _luoiKhoanhKhac(danhSach),
                ),
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 13,
              child: _thanhCongCuNoi(),
            ),

            if (_hienMenuNguoiXem) _lopMenuNguoiXem(),
          ],
        ),
      ),
    );
  }

  Widget _luoiKhoanhKhac(List<KhoanhKhacMau> danhSach) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: danhSach.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemBuilder: (context, index) {
        final khoanhKhac = danhSach[index];

        return InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.trangHinhAnhChiTiet,
              arguments: {
                'duongDanAnh': khoanhKhac.duongDanAnh,
                'viTri': khoanhKhac.viTri,
              },
            );
          },
          child: _anhKhoanhKhac(khoanhKhac),
        );
      },
    );
  }

  Widget _anhKhoanhKhac(KhoanhKhacMau khoanhKhac) {
    if (khoanhKhac.laAnhMay &&
        khoanhKhac.duongDanAnh.startsWith('/') &&
        File(khoanhKhac.duongDanAnh).existsSync()) {
      return Image.file(
        File(khoanhKhac.duongDanAnh),
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      khoanhKhac.duongDanAnh,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: const Icon(
            LucideIcons.image,
            color: Colors.black54,
            size: 26,
          ),
        );
      },
    );
  }

  Widget _thanhCongCuNoi() {
    return Center(
      child: Container(
        height: 36,
        width: 132,
        decoration: BoxDecoration(
          color: const Color(0xFF242424).withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
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
                  size: 20,
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
            width: 18,
            height: 18,
            child: Wrap(
              spacing: 3,
              runSpacing: 3,
              children: List.generate(4, (index) {
                return Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 1.5),
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
                top: 72,
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