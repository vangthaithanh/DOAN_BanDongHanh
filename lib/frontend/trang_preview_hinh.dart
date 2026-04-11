import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

class PreviewPage extends StatefulWidget {
  final String imagePath;

  const PreviewPage({super.key, required this.imagePath});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  static const Color blue = Color(0xFF4AA8FF);

  bool isPosted = false;
  final TextEditingController captionController = TextEditingController();

  // ===== LƯU ẢNH =====
  Future<String> saveImageToApp(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();

    final fileName =
    DateTime.now().millisecondsSinceEpoch.toString();

    final newFile = File('${dir.path}/$fileName.jpg');

    await imageFile.copy(newFile.path);

    return newFile.path;
  }

  // ===== SUBMIT (SEND) =====
  void handleSubmit() async {
    setState(() {
      isPosted = true;
    });

    final file = File(widget.imagePath);

    //  lưu ảnh
    final savedPath = await saveImageToApp(file);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      //  TRẢ VỀ cho CameraPage
      Navigator.pop(context, savedPath);
    }
  }

  @override
  void dispose() {
    captionController.dispose();
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

                  // ===== ẢNH =====
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== CAPTION =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: captionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Thêm hành trình",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            LucideIcons.pencil,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ===== BUTTONS =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(
                            LucideIcons.x,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        //  SEND
                        GestureDetector(
                          onTap: isPosted ? null : handleSubmit,
                          child: AnimatedSwitcher(
                            duration:
                            const Duration(milliseconds: 300),
                            child: Icon(
                              isPosted
                                  ? LucideIcons.check
                                  : LucideIcons.send,
                              key: ValueKey(isPosted),
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),

                        //  SAVE
                        GestureDetector(
                          onTap: () async {
                            final file = File(widget.imagePath);
                            await saveImageToApp(file);

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text("Đã lưu ảnh 📸"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: const Icon(
                            LucideIcons.bookmark,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _bottomNav(),
    );
  }

  // ===== TOP BAR =====
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: Colors.white),
          const Expanded(
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
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/trang_thongbao');
            },
            child: const Icon(
              LucideIcons.bell,
              color: Colors.white,
              size: 23,
            ),
          ),        ],
      ),
    );
  }

  Widget _bottomNav() {
    return const SafeArea(
      top: false,
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(LucideIcons.house, color: Colors.white),
            Icon(LucideIcons.aperture, color: blue),
            Icon(LucideIcons.mapPin, color: Colors.white),
            Icon(LucideIcons.messagesSquare, color: Colors.white),
            Icon(LucideIcons.userRound, color: Colors.white),
          ],
        ),
      ),
    );
  }
}