import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:do_an/frontend/trang_hinh_anh_chi_tiết.dart';

class GalleryPage extends StatefulWidget {
  final List<String> images;

  const GalleryPage({super.key, required this.images});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  static const Color blue = Color(0xFF4AA8FF);

  // ===== DROPDOWN =====
  bool showPeople = false;
  String selectedUser = "Mọi người";

  final List<String> users = [
    "Mọi người",
    "BongAnhHung",
    "Buji",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _topBar(),

                Expanded(
                  child: widget.images.isEmpty
                      ? const Center(
                    child: Text(
                      "Chưa có ảnh",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                      : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.images.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                      itemBuilder: (context, index) {
                        final file = File(widget.images[index]);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageDetailPage(
                                  imagePath: widget.images[index],
                                  userName: selectedUser,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: file.existsSync()
                                ? Image.file(file, fit: BoxFit.cover)
                                : Container(
                              color: const Color(0xFF222222),
                              child: const Icon(
                                LucideIcons.imageOff,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        );
                      }
                  ),
                ),
              ],
            ),

            if (showPeople) _overlayDropdown(),
          ],
        ),
      ),

      bottomNavigationBar: _bottomNav(context),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Row(
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
              ),
            ],
          ),

          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              setState(() {
                showPeople = !showPeople;
              });
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedUser,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.chevronDown,
                    color: Colors.white,
                    size: 16,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== DROPDOWN OVERLAY =====
  Widget _overlayDropdown() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showPeople = false;
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                top: 85,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: users.map((user) {
                          final isSelected = user == selectedUser;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedUser = user;
                                showPeople = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 6,
                                    backgroundColor: isSelected
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    user,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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