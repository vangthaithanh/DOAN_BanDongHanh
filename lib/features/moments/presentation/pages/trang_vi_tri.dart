import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
// NOTE SỬA: thêm 2 thư viện này để lấy GPS và đổi GPS ra địa chỉ thật
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TrangViTri extends StatefulWidget {
  const TrangViTri({super.key});

  @override
  State<TrangViTri> createState() => _TrangViTriState();
}

class _TrangViTriState extends State<TrangViTri> {
  final TextEditingController timKiemController = TextEditingController();

  final List<String> dsViTri = [
    'Trường đại học công thương',
    'AEON Mall Bình Tân',
    'Đầm Sen',
    'Công viên Gia Định',
    'Landmark 81',
  ];

  String? viTriDangChon;

  // NOTE SỬA: biến lưu GPS thật
  double? latitudeDangChon;
  double? longitudeDangChon;

  // NOTE SỬA: địa chỉ thật từ GPS
  String? diaChiHienTai;
  double? latitudeHienTai;
  double? longitudeHienTai;

  bool dangLayViTri = false;
  String? loiViTri;

  List<String> ketQua = [];

  @override
  void initState() {
    super.initState();
    ketQua = dsViTri;

    // NOTE SỬA: vô trang là tự lấy GPS hiện tại
    layViTriHienTai();
  }

  @override
  void dispose() {
    timKiemController.dispose();
    super.dispose();
  }

  void timKiem(String value) {
    setState(() {
      ketQua = dsViTri
          .where((e) => e.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  // NOTE SỬA:
  // Hàm này dùng để ghép địa chỉ cho sạch.
  // Không dùng p.name vì p.name nhiều máy trả về "26/2",
  // còn p.street trả về "26/2 Đ. số 8",
  // nếu ghép cả 2 sẽ bị lỗi "26/2, 26/2 Đ. số 8..."
  String _taoDiaChiTuPlacemark(Placemark p) {
    final List<String?> rawParts = [
      p.street,
      p.subLocality,
      p.locality,
      p.subAdministrativeArea,
      p.administrativeArea,
      p.country,
    ];

    final List<String> parts = [];

    for (final item in rawParts) {
      final value = item?.trim();

      if (value == null || value.isEmpty) continue;
      if (value.toLowerCase() == 'unnamed road') continue;

      final valueLower = value.toLowerCase();

      final daTonTai = parts.any((old) {
        final oldLower = old.toLowerCase();

        // NOTE SỬA:
        // Chặn trùng tuyệt đối hoặc trùng kiểu:
        // "26/2" nằm trong "26/2 Đ. số 8"
        return oldLower == valueLower ||
            oldLower.contains(valueLower) ||
            valueLower.contains(oldLower);
      });

      if (daTonTai) continue;

      parts.add(value);
    }

    if (parts.isEmpty) {
      return '';
    }

    return parts.join(', ');
  }

  // NOTE SỬA: hàm lấy vị trí hiện tại bằng GPS
  Future<void> layViTriHienTai() async {
    setState(() {
      dangLayViTri = true;
      loiViTri = null;
    });

    try {
      final bool daBatDichVuViTri = await Geolocator.isLocationServiceEnabled();

      if (!daBatDichVuViTri) {
        setState(() {
          loiViTri = 'Bạn chưa bật GPS/vị trí trên thiết bị';
          dangLayViTri = false;
        });
        return;
      }

      LocationPermission quyen = await Geolocator.checkPermission();

      if (quyen == LocationPermission.denied) {
        quyen = await Geolocator.requestPermission();
      }

      if (quyen == LocationPermission.denied) {
        setState(() {
          loiViTri = 'Bạn chưa cấp quyền truy cập vị trí';
          dangLayViTri = false;
        });
        return;
      }

      if (quyen == LocationPermission.deniedForever) {
        setState(() {
          loiViTri =
              'Quyền vị trí đã bị từ chối vĩnh viễn. Vào cài đặt để bật lại.';
          dangLayViTri = false;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      latitudeHienTai = position.latitude;
      longitudeHienTai = position.longitude;

      String diaChi = 'Vị trí hiện tại: $latitudeHienTai, $longitudeHienTai';

      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          latitudeHienTai!,
          longitudeHienTai!,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          final diaChiDaXuLy = _taoDiaChiTuPlacemark(p);

          if (diaChiDaXuLy.isNotEmpty) {
            diaChi = diaChiDaXuLy;
          }
        }
      } catch (_) {
        diaChi = 'Vị trí hiện tại: $latitudeHienTai, $longitudeHienTai';
      }

      setState(() {
        diaChiHienTai = diaChi;

        // NOTE SỬA:
        // Tự chọn luôn vị trí hiện tại sau khi lấy xong.
        // Như vậy người dùng chỉ cần bấm "Thêm vị trí" là lưu được.
        viTriDangChon = diaChiHienTai;
        latitudeDangChon = latitudeHienTai;
        longitudeDangChon = longitudeHienTai;

        dangLayViTri = false;
      });
    } catch (e) {
      setState(() {
        loiViTri = 'Không lấy được vị trí hiện tại';
        dangLayViTri = false;
      });
    }
  }

  // NOTE SỬA: chọn vị trí hiện tại có GPS thật
  void chonViTriHienTai() {
    if (diaChiHienTai == null ||
        latitudeHienTai == null ||
        longitudeHienTai == null) {
      return;
    }

    setState(() {
      viTriDangChon = diaChiHienTai;
      latitudeDangChon = latitudeHienTai;
      longitudeDangChon = longitudeHienTai;
    });
  }

  // NOTE SỬA: chọn vị trí cứng thì chỉ có tên, chưa có GPS thật
  void chonViTriCoSan(String item) {
    setState(() {
      viTriDangChon = item;
      latitudeDangChon = null;
      longitudeDangChon = null;
    });
  }

  // NOTE SỬA: trả về Map thay vì trả về String
  void themViTri() {
    if (viTriDangChon == null) {
      Navigator.pop(context);
      return;
    }

    Navigator.pop(context, {
      'nearby_place_name': viTriDangChon,
      'latitude': latitudeDangChon,
      'longitude': longitudeDangChon,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
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
                        borderRadius: BorderRadius.circular(23),
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

              const SizedBox(height: 24),

              // NOTE SỬA: khung vị trí hiện tại lấy bằng GPS
              _khungViTriHienTai(),

              const SizedBox(height: 20),

              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: timKiemController,
                  onChanged: timKiem,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(LucideIcons.search, color: Color(0xFFB0B0B0)),
                    hintText: 'Tìm Kiếm',
                    hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              Expanded(
                child: ListView.builder(
                  itemCount: ketQua.length,
                  itemBuilder: (context, index) {
                    final item = ketQua[index];

                    final dangChon = viTriDangChon == item;

                    return GestureDetector(
                      onTap: () {
                        chonViTriCoSan(item);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                color: dangChon ? Colors.blue : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Vị trí gợi ý có sẵn',
                              style: TextStyle(
                                color: Color(0xFF9A9A9A),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
                padding: const EdgeInsets.only(bottom: 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: dangLayViTri ? null : themViTri,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C98D6),
                      disabledBackgroundColor: const Color(0xFF3A3A3C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
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

  // NOTE SỬA: widget riêng cho vị trí GPS hiện tại
  Widget _khungViTriHienTai() {
    final bool dangChon =
        viTriDangChon != null && viTriDangChon == diaChiHienTai;

    if (dangLayViTri) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đang lấy vị trí hiện tại...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (loiViTri != null) {
      return GestureDetector(
        onTap: layViTriHienTai,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.redAccent),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.mapPinOff, color: Colors.redAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$loiViTri. Nhấn để thử lại.',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: chonViTriHienTai,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dangChon ? Colors.blue : const Color(0xFF3A3A3C),
            width: dangChon ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.locateFixed,
              color: dangChon ? Colors.blue : Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vị trí hiện tại',
                    style: TextStyle(
                      color: dangChon ? Colors.blue : Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    diaChiHienTai ?? 'Chưa có địa chỉ',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  if (latitudeHienTai != null && longitudeHienTai != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'GPS: $latitudeHienTai, $longitudeHienTai',
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
