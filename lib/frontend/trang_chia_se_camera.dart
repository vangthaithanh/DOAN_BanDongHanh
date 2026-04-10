import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:do_an/frontend/trang_preview_hinh.dart';
import 'package:do_an/frontend/trang_gallery_khoanhkhac.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  int currentCameraIndex = 0;

  List<String> tempImages = [];

  static const Color blue = Color(0xFF4AA8FF);

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      cameras = await availableCameras();

      controller = CameraController(
        cameras![currentCameraIndex],
        ResolutionPreset.high,
      );

      await controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Camera error: $e");
    }
  }

  // Lật camera
  Future<void> switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    currentCameraIndex =
        (currentCameraIndex + 1) % cameras!.length;

    controller = CameraController(
      cameras![currentCameraIndex],
      ResolutionPreset.high,
    );

    await controller!.initialize();
    if (mounted) setState(() {});
  }

  // CHỤP ẢNH
  Future<void> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return;

    final image = await controller!.takePicture();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PreviewPage(imagePath: image.path),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        tempImages.add(result);
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),

            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ===== CAMERA =====
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: controller != null &&
                            controller!.value.isInitialized
                            ? AspectRatio(
                          aspectRatio:
                          controller!.value.aspectRatio,
                          child: CameraPreview(controller!),
                        )
                            : const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== VỊ TRÍ =====
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.mapPin,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text("Thêm vị trí",
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ===== THANH CHỤP =====
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GalleryPage(images: tempImages),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.window_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        //  nút chụp
                        GestureDetector(
                          onTap: takePicture,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: blue, width: 3),
                            ),
                            child: const CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),

                        // lật cam
                        GestureDetector(
                          onTap: switchCamera,
                          child: const Icon(
                            LucideIcons.refreshCcw,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _bottomNav(context),
    );
  }

  // ===== TOP BAR =====
  Widget _topBar() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Icon(LucideIcons.search, color: Colors.white),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Go',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: 'Mate',
                    style: TextStyle(
                      color: Color(0xFF4AA8FF),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Icon(LucideIcons.bell, color: Colors.white),
        ],
      ),
    );
  }

  // ===== BOTTOM NAV =====
  Widget _bottomNav(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Color(0xFF1E1E1E)),
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/trang-chu', (route) => false);
              },
              child: const Icon(LucideIcons.house,
                  color: Colors.white),
            ),
            const Icon(LucideIcons.aperture,
                color: blue),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/map');
              },
              child: const Icon(LucideIcons.mapPin,
                  color: Colors.white),
            ),
            const Icon(LucideIcons.messagesSquare,
                color: Colors.white),
            InkWell(
              onTap: () {
                Navigator.pushNamed(
                    context, '/trang-canhan');
              },
              child: const Icon(LucideIcons.userRound,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}