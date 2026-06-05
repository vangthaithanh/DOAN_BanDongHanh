import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../data/khoanh_khac_service.dart';
import '../../data/model/khoanh_khac_mau.dart';
import '../pages/trang_hinh_anh_chi_tiet.dart';
import '../widgets/menu_nguoi_xem.dart';
import '../widgets/thanh_tren_khoanhkhac.dart';

class TrangGalleryKhoanhKhac extends StatefulWidget {
  const TrangGalleryKhoanhKhac({super.key});

  @override
  State<TrangGalleryKhoanhKhac> createState() => _TrangGalleryKhoanhKhacState();
}

class _TrangGalleryKhoanhKhacState extends State<TrangGalleryKhoanhKhac> {
  bool _hienMenuNguoiXem = false;
  Map<String, dynamic>? _selectedProfile;
  List<Map<String, dynamic>> _danhSachProfiles = [];

  final KhoanhKhacService _service = KhoanhKhacService();
  late Future<List<KhoanhKhacMau>> _future;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadData();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await _service.getTatCaProfiles();
      setState(() {
        _danhSachProfiles = profiles;
      });
    } catch (e) {
      debugPrint("Lỗi tải profiles: $e");
    }
  }

  void _loadData() {
    setState(() {
      _future = _service.getKhoanhKhac(
        profileId: _selectedProfile?['id']?.toString(),
      );
    });
  }

  void _doiTrangThaiMenu() {
    setState(() => _hienMenuNguoiXem = !_hienMenuNguoiXem);
  }

  void _tatMenu() {
    setState(() => _hienMenuNguoiXem = false);
  }

  void _onProfileSelected(Map<String, dynamic>? profile) {
    setState(() {
      _selectedProfile = profile;
      _hienMenuNguoiXem = false;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    String tenHienTai = 'Mọi người';
    if (_selectedProfile != null) {
      tenHienTai =
          _selectedProfile!['nickname'] ??
          _selectedProfile!['full_name'] ??
          'Người dùng';
    }

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
                  tenHienTai: tenHienTai,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<KhoanhKhacMau>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Lỗi tải dữ liệu: ${snapshot.error}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      final danhSach = snapshot.data;
                      if (danhSach == null || danhSach.isEmpty) {
                        return const Center(
                          child: Text(
                            "Chưa có khoảnh khắc nào",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return _luoiKhoanhKhac(danhSach);
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

  Widget _luoiKhoanhKhac(List<KhoanhKhacMau> danhSach) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: danhSach.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final item = danhSach[index];
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrangHinhAnhChiTiet(
                  danhSachMoments: danhSach,
                  indexBatDau: index,
                ),
              ),
            );
            if (result == true) {
              _loadData();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(item.duongDanAnh),
          ),
        );
      },
    );
  }

  Widget _buildImage(String duongDanAnh) {
    if (duongDanAnh.startsWith('http')) {
      return Image.network(
        duongDanAnh,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade900,
          child: const Icon(Icons.broken_image, color: Colors.white),
        ),
      );
    }
    final path = duongDanAnh.replaceFirst('file://', '');
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade900,
        child: const Icon(Icons.broken_image, color: Colors.white),
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
            children: [
              Positioned(
                top: 72,
                left: 0,
                right: 0,
                child: Center(
                  child: MenuNguoiXem(
                    danhSachProfiles: _danhSachProfiles,
                    onProfileSelected: _onProfileSelected,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dongViTriDep(String? diaChi) {
    final text = diaChi?.trim();

    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.48),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
