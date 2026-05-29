import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TrangViTri extends StatefulWidget {
  const TrangViTri({super.key});

  @override
  State<TrangViTri> createState() =>
      _TrangViTriState();
}

class _TrangViTriState extends State<TrangViTri> {
  final TextEditingController timKiemController =
  TextEditingController();

  final List<String> dsViTri = [
    'Trường đại học công thương',
    'AEON Mall Bình Tân',
    'Đầm Sen',
    'Công viên Gia Định',
    'Landmark 81',
  ];

  String? viTriDangChon;

  List<String> ketQua = [];

  @override
  void initState() {
    super.initState();
    ketQua = dsViTri;
  }

  void timKiem(String value) {
    setState(() {
      ketQua = dsViTri
          .where(
            (e) => e.toLowerCase().contains(
          value.toLowerCase(),
        ),
      )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 12),

              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius:
                        BorderRadius.circular(23),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        'Vị trí',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 46),
                ],
              ),

              const SizedBox(height: 34),

              const Text(
                'Chọn vị trí gắn thẻ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Những người mà bạn chia sẻ nội dung này\n'
                    'có thể nhìn thấy vị trí gắn thẻ và xem vị trí\n'
                    'trên bản đồ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                height: 46,
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: timKiemController,
                  onChanged: timKiem,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      LucideIcons.search,
                      color: Color(0xFFB0B0B0),
                    ),
                    hintText: 'Tìm Kiếm',
                    hintStyle: TextStyle(
                      color: Color(0xFFB0B0B0),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Expanded(
                child: ListView.builder(
                  itemCount: ketQua.length,
                  itemBuilder: (context, index) {
                    final item = ketQua[index];

                    final dangChon =
                        viTriDangChon == item;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          viTriDangChon = item;
                        });
                      },
                      child: Container(
                        margin:
                        const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                color: dangChon
                                    ? Colors.blue
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              '7,8km  140 Lê Trọng Tấn',
                              style: TextStyle(
                                color:
                                Color(0xFF9A9A9A),
                                fontSize: 15,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding:
                const EdgeInsets.only(bottom: 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        viTriDangChon,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF5C98D6),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Thêm vị trí',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
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
}