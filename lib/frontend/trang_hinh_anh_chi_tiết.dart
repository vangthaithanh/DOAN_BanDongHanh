import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ImageDetailPage extends StatelessWidget {
  final String imagePath;
  final String userName;

  const ImageDetailPage({
    super.key,
    required this.imagePath,
    required this.userName,
  });

  static const Color blue = Color(0xFF4AA8FF);

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Column(
          children: [
            // ===== TOP BAR =====
            const Padding(
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
            ),

            const SizedBox(height: 10),

            // ===== IMAGE =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: file.existsSync()
                        ? Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                        : const Center(
                      child: Icon(
                        LucideIcons.imageOff,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== USER INFO =====
            Column(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: blue,
                ),
                const SizedBox(height: 6),
                Text(
                  "BongAnhHung",
                  style: const TextStyle(color: Colors.white),
                ),
                const Text(
                  "3 tiếng trước",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ===== CHAT INPUT =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Gửi tin nhắn...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  suffixIcon: Icon(
                    LucideIcons.smile,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== ACTIONS =====
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(LucideIcons.grid2x2, color: Colors.white),
                ),

                const SizedBox(width: 30),

                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/trang_chia_se_camera');
                  },
                  child: const Icon(LucideIcons.circle, color: blue),
                ),

                const SizedBox(width: 30),

                const Icon(LucideIcons.download, color: Colors.white),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      bottomNavigationBar: _bottomNav(context),
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/trang-chu', (route) => false);
              },
              child: const Icon(LucideIcons.house,
                  color: Colors.white),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/trang_chia_se_camera');
              },
              child: const Icon(
                LucideIcons.aperture,
                color: Colors.white,
              ),
            ),
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
                Navigator.pushNamed(context, '/trang-canhan');
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