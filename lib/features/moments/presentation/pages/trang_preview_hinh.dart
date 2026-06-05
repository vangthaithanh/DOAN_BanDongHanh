import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../widgets/thanh_tren_khoanhkhac.dart';

class TrangPreviewHinh extends StatefulWidget {
  final String? duongDanAnh;

  const TrangPreviewHinh({super.key, this.duongDanAnh});

  @override
  State<TrangPreviewHinh> createState() => _TrangPreviewHinhState();
}

class _TrangPreviewHinhState extends State<TrangPreviewHinh> {
  String? viTriDaChon;

  // NOTE SỬA: thêm 2 biến lưu GPS
  double? latitudeDaChon;
  double? longitudeDaChon;

  String? duongDanAnh;
  bool _dangGui = false;

  @override
  void initState() {
    super.initState();
    duongDanAnh = widget.duongDanAnh;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() => duongDanAnh = args);
      } else if (args is Map && args['duongDanAnh'] != null) {
        setState(() => duongDanAnh = args['duongDanAnh']);
      }
    });
  }

  // 🚀 GỬI LÊN SUPABASE
  Future<void> _guiAnh(BuildContext context) async {
    if (duongDanAnh == null || duongDanAnh!.isEmpty || _dangGui) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _dangGui = true);

    try {
      // 1. Upload ảnh lên Storage
      final localPath = duongDanAnh!.replaceFirst('file://', '');
      final file = File(localPath);
      if (!file.existsSync()) throw Exception('Không tìm thấy file ảnh');

      final ext = localPath.split('.').last.toLowerCase();
      final storagePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await supabase.storage.from('moment-media').upload(storagePath, file);
      final imageUrl =
          supabase.storage.from('moment-media').getPublicUrl(storagePath);

      // 2. Lưu record vào bảng moments
      await supabase.from('moments').insert({
        'profile_id': user.id,
        'image_url': imageUrl,
        'nearby_place_name': viTriDaChon,
        'latitude': latitudeDaChon,
        'longitude': longitudeDaChon,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'expires_at': DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String(),
        'status': 'active',
      });

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.trangGalleryKhoanhKhac,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangGui = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    return double.tryParse(value.toString());
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
                  final chieuCao = (constraints.maxHeight * 0.58).clamp(
                    300.0,
                    405.0,
                  );
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      _khungAnh(chieuCao),
                      const Spacer(),
                      _hangNutDuoi(),
                      const SizedBox(height: 30),
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
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: _hienThiAnh()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(child: _nutThemViTri()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hienThiAnh() {
    final path = duongDanAnh ?? '';
    if (path.isEmpty) {
      return const Center(
        child: Text('Không có ảnh', style: TextStyle(color: Colors.white)),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    }

    final file = File(path.replaceFirst('file://', ''));
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return const Center(
      child: Icon(Icons.broken_image, color: Colors.white54, size: 50),
    );
  }

  Widget _nutThemViTri() {
    return InkWell(
      onTap: () async {
        final res = await Navigator.pushNamed(context, AppRoutes.trangViTri);

        if (res == null) return;

        // NOTE SỬA: TrangViTri giờ trả về Map gồm tên địa điểm + GPS
        if (res is Map) {
          setState(() {
            viTriDaChon = res['nearby_place_name']?.toString();
            latitudeDaChon = _toDouble(res['latitude']);
            longitudeDaChon = _toDouble(res['longitude']);
          });
        } else {
          // NOTE: nếu route cũ còn trả String thì vẫn không lỗi
          setState(() {
            viTriDaChon = res.toString();
            latitudeDaChon = null;
            longitudeDaChon = null;
          });
        }
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          viTriDaChon ?? 'Thêm vị trí',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _hangNutDuoi() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.circleX, color: Colors.white, size: 30),
        ),
        _dangGui
            ? const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 3,
                ),
              )
            : IconButton(
                onPressed: () => _guiAnh(context),
                icon: const Icon(
                  LucideIcons.sendHorizontal,
                  color: Colors.blue,
                  size: 50,
                ),
              ),
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.download, color: Colors.white, size: 30),
        ),
      ],
    );
  }
}
