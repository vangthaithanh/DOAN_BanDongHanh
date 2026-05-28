import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../data/mock/mock_khoanhkhac.dart';
import '../widgets/thanh_tren_khoanhkhac.dart';

class TrangPreviewHinh extends StatelessWidget {
  final String? duongDanAnh;

  const TrangPreviewHinh({
    super.key,
    this.duongDanAnh,
  });

  void _guiAnh(BuildContext context) {
    if (duongDanAnh != null && duongDanAnh!.trim().isNotEmpty) {
      KhoLuuKhoanhKhacTam.themAnh(duongDanAnh!);
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.trangGalleryKhoanhKhac,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const AppBottomNav(activeTab: MainTab.moments),
      body: SafeArea(
        child: Column(
          children: [
            const ThanhTrenKhoanhKhac(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chieuCaoKhung = constraints.maxHeight * 0.58;
                  final chieuCaoHopLy = chieuCaoKhung.clamp(300.0, 405.0);

                  return Column(
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.035),

                      _khungAnh(chieuCaoHopLy),

                      const Spacer(),

                      _hangNutDuoi(context),

                      SizedBox(height: constraints.maxHeight * 0.04),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _khungAnh(double chieuCao) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29),
      child: Container(
        height: chieuCao,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(31),
          border: Border.all(
            color: const Color(0xFF2B2B2B),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: _hienThiAnh(),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: _nutThemViTri(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hienThiAnh() {
    if (duongDanAnh != null &&
        duongDanAnh!.startsWith('/') &&
        File(duongDanAnh!).existsSync()) {
      return Image.file(
        File(duongDanAnh!),
        fit: BoxFit.cover,
      );
    }

    return const Center(
      child: Text(
        'Ảnh',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _nutThemViTri() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 19),
      decoration: BoxDecoration(
        color: const Color(0xFF292929),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.mapPin,
            color: Colors.white,
            size: 22,
          ),
          SizedBox(width: 8),
          Text(
            'Thêm vị trí',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hangNutDuoi(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 67),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(28),
            child: const SizedBox(
              width: 54,
              height: 54,
              child: Icon(
                LucideIcons.circleX,
                color: Colors.white,
                size: 31,
              ),
            ),
          ),

          InkWell(
            onTap: () {
              _guiAnh(context);
            },
            borderRadius: BorderRadius.circular(42),
            child: Container(
              width: 82,
              height: 82,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4AA8FF),
                  width: 4,
                ),
              ),
              child: const Icon(
                LucideIcons.sendHorizontal,
                color: Colors.white,
                size: 45,
              ),
            ),
          ),

          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(28),
            child: const SizedBox(
              width: 54,
              height: 54,
              child: Icon(
                LucideIcons.download,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}