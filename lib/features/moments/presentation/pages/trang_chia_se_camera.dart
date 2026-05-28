import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../widgets/thanh_tren_khoanhkhac.dart';

class TrangChiaSeCamera extends StatefulWidget {
  const TrangChiaSeCamera({super.key});

  @override
  State<TrangChiaSeCamera> createState() => _TrangChiaSeCameraState();
}

class _TrangChiaSeCameraState extends State<TrangChiaSeCamera> {
  CameraController? _cameraController;
  List<CameraDescription> _danhSachCamera = [];
  int _cameraDangChon = 0;
  bool _dangKhoiTao = true;

  @override
  void initState() {
    super.initState();
    _khoiTaoCamera();
  }

  Future<void> _khoiTaoCamera() async {
    try {
      _danhSachCamera = await availableCameras();

      if (_danhSachCamera.isEmpty) {
        if (!mounted) return;
        setState(() {
          _dangKhoiTao = false;
        });
        return;
      }

      await _moCamera(_cameraDangChon);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dangKhoiTao = false;
      });
    }
  }

  Future<void> _moCamera(int index) async {
    await _cameraController?.dispose();

    final controller = CameraController(
      _danhSachCamera[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _dangKhoiTao = false;
    });
  }

  Future<void> _doiCamera() async {
    if (_danhSachCamera.length <= 1) return;

    setState(() {
      _dangKhoiTao = true;
      _cameraDangChon = (_cameraDangChon + 1) % _danhSachCamera.length;
    });

    await _moCamera(_cameraDangChon);
  }

  Future<void> _chupAnh() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      Navigator.pushNamed(context, AppRoutes.trangPreviewHinh);
      return;
    }

    final anh = await controller.takePicture();

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      AppRoutes.trangPreviewHinh,
      arguments: anh.path,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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
                  final chieuCaoKhung = constraints.maxHeight * 0.55;
                  final chieuCaoHopLy = chieuCaoKhung.clamp(270.0, 360.0);

                  return Column(
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.035),

                      _khungCamera(chieuCaoHopLy),

                      SizedBox(height: constraints.maxHeight * 0.075),

                      _hangDieuKhien(),

                      const Spacer(),
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

  Widget _khungCamera(double chieuCao) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Container(
        height: chieuCao,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: const Color(0xFF2B2B2B),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _noiDungCamera(),
      ),
    );
  }

  Widget _noiDungCamera() {
    final controller = _cameraController;

    if (_dangKhoiTao) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF4AA8FF),
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _hangDieuKhien() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.trangGalleryKhoanhKhac);
            },
            borderRadius: BorderRadius.circular(28),
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.chevronDown,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Lịch sử',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          GestureDetector(
            onTap: _chupAnh,
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4AA8FF),
                  width: 3,
                ),
              ),
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          InkWell(
            onTap: _doiCamera,
            borderRadius: BorderRadius.circular(28),
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Icon(
                LucideIcons.refreshCw,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}