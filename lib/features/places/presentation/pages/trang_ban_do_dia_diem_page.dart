import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';

/// NOTE SỬA:
/// Trang bản đồ địa điểm du lịch.
/// Luồng:
/// - Lấy danh sách địa điểm từ bảng places trong Supabase.
/// - Chỉ lấy địa điểm active và có latitude/longitude.
/// - Vẽ marker lên OpenStreetMap bằng flutter_map, không dùng Google Map SDK.
/// - Bấm marker sẽ hiện card thông tin địa điểm.
/// - Bấm "Đường đi" sẽ lấy GPS hiện tại rồi mở Google Maps.
/// - Nếu đi từ trang chi tiết qua map thì tự zoom tới đúng địa điểm đó.
class TrangBanDoDiaDiemPage extends StatefulWidget {
  const TrangBanDoDiaDiemPage({super.key});

  @override
  State<TrangBanDoDiaDiemPage> createState() => _TrangBanDoDiaDiemPageState();
}

class _TrangBanDoDiaDiemPageState extends State<TrangBanDoDiaDiemPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  final LatLng _vietnamCenter = const LatLng(14.0583, 108.2772);

  List<_MapPlace> _tatCaDiaDiem = [];
  _MapPlace? _diaDiemDangChon;

  // NOTE SỬA:
  // Biến nhận id địa điểm từ trang chi tiết.
  // Khi trang chi tiết bấm "Xem vị trí" hoặc icon map,
  // nó truyền selectedPlaceId qua đây để map tự chọn đúng marker.
  int? _selectedPlaceIdFromDetail;
  bool _daDocArgument = false;

  bool _dangTai = true;
  String? _loi;
  String _tuKhoa = '';

  @override
  void initState() {
    super.initState();
    _taiDiaDiemLenBanDo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // NOTE SỬA:
    // Chỉ đọc arguments 1 lần để tránh bị đọc lại nhiều lần khi setState.
    if (_daDocArgument) return;
    _daDocArgument = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      _selectedPlaceIdFromDetail = args['selectedPlaceId'] as int?;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_MapPlace> get _ketQuaHienThi {
    final keyword = _normalize(_tuKhoa);

    final result = _tatCaDiaDiem.where((item) {
      if (keyword.isEmpty) return true;

      final text = _normalize(
        '${item.name} ${item.province} ${item.district ?? ''} '
        '${item.address ?? ''} ${item.keywords ?? ''} ${item.description ?? ''}',
      );

      return text.contains(keyword);
    }).toList();

    result.sort((a, b) {
      final ratingCompare = b.avgRating.compareTo(a.avgRating);
      if (ratingCompare != 0) return ratingCompare;

      return b.totalSaves.compareTo(a.totalSaves);
    });

    return result;
  }

  Future<void> _taiDiaDiemLenBanDo() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final response = await _supabase
          .from('places')
          .select(
            'id, category_id, name, province, district, address, latitude, longitude, opening_hours, price, avg_rating, total_reviews, total_saves, keywords, description, status',
          )
          .eq('status', 'active')
          .order('total_saves', ascending: false);

      final data = (response as List)
          .map((json) => _MapPlace.fromJson(Map<String, dynamic>.from(json)))
          .where((item) => item.hasLatLng)
          .toList();

      if (!mounted) return;

      setState(() {
        _tatCaDiaDiem = data;
        _dangTai = false;
      });

      if (data.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          // NOTE SỬA:
          // Nếu mở map từ trang chi tiết thì tự zoom tới đúng địa điểm.
          // Nếu mở map từ trang danh sách thì zoom bao quát tất cả địa điểm.
          if (_selectedPlaceIdFromDetail != null) {
            _chonDiaDiemTuTrangChiTiet(data);
          } else {
            _diChuyenDenKhuVucCoDiaDiem(data);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loi = e.toString().replaceFirst('Exception: ', '');
        _dangTai = false;
      });
    }
  }

  void _diChuyenDenKhuVucCoDiaDiem(List<_MapPlace> places) {
    if (places.isEmpty) return;

    double minLat = places.first.latitude!;
    double maxLat = places.first.latitude!;
    double minLng = places.first.longitude!;
    double maxLng = places.first.longitude!;

    for (final item in places) {
      minLat = min(minLat, item.latitude!);
      maxLat = max(maxLat, item.latitude!);
      minLng = min(minLng, item.longitude!);
      maxLng = max(maxLng, item.longitude!);
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    final latDelta = (maxLat - minLat).abs();
    final lngDelta = (maxLng - minLng).abs();
    final maxDelta = max(latDelta, lngDelta);

    double zoom = 5.3;
    if (maxDelta < 0.03) {
      zoom = 15;
    } else if (maxDelta < 0.1) {
      zoom = 13;
    } else if (maxDelta < 0.5) {
      zoom = 10.5;
    } else if (maxDelta < 1.5) {
      zoom = 8.5;
    } else if (maxDelta < 4) {
      zoom = 7;
    }

    _mapController.move(center, zoom);
  }

  // NOTE SỬA:
  // Khi mở map từ trang chi tiết, tự chọn marker và hiện card địa điểm đó.
  void _chonDiaDiemTuTrangChiTiet(List<_MapPlace> places) {
    final selectedId = _selectedPlaceIdFromDetail;

    if (selectedId == null) {
      _diChuyenDenKhuVucCoDiaDiem(places);
      return;
    }

    _MapPlace? selectedPlace;

    for (final item in places) {
      if (item.id == selectedId) {
        selectedPlace = item;
        break;
      }
    }

    if (selectedPlace == null) {
      _diChuyenDenKhuVucCoDiaDiem(places);
      return;
    }

    setState(() {
      _diaDiemDangChon = selectedPlace;
    });

    _mapController.move(
      LatLng(selectedPlace.latitude!, selectedPlace.longitude!),
      15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _ketQuaHienThi;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _vietnamCenter,
                initialZoom: 5.4,
                minZoom: 4,
                maxZoom: 18,
                onTap: (_, __) {
                  setState(() {
                    _diaDiemDangChon = null;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gomate.app',
                ),
                MarkerLayer(markers: [...places.map(_buildPlaceMarker)]),
              ],
            ),

            Positioned(
              left: 14,
              right: 14,
              top: 12,
              child: _topSearchBar(places.length),
            ),

            Positioned(
              right: 14,
              bottom: _diaDiemDangChon == null ? 24 : 178,
              child: Column(
                children: [
                  _roundMapButton(
                    icon: Icons.my_location_rounded,
                    onTap: _diDenViTriCuaToi,
                  ),
                  const SizedBox(height: 10),
                  _roundMapButton(
                    icon: Icons.refresh_rounded,
                    onTap: _taiDiaDiemLenBanDo,
                  ),
                ],
              ),
            ),

            if (_dangTai) _loadingBox(),

            if (!_dangTai && _loi != null) _errorBox(),

            if (!_dangTai && _loi == null && places.isEmpty) _emptyBox(),

            if (_diaDiemDangChon != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: _placeInfoCard(_diaDiemDangChon!),
              ),
          ],
        ),
      ),
    );
  }

  Marker _buildPlaceMarker(_MapPlace place) {
    final isSelected = _diaDiemDangChon?.id == place.id;
    final color = _markerColor(place);

    return Marker(
      width: isSelected ? 54 : 46,
      height: isSelected ? 54 : 46,
      point: LatLng(place.latitude!, place.longitude!),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _diaDiemDangChon = place;
          });

          _mapController.move(LatLng(place.latitude!, place.longitude!), 14.5);
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: isSelected ? 1.14 : 1,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              _markerIcon(place),
              color: Colors.white,
              size: isSelected ? 25 : 21,
            ),
          ),
        ),
      ),
    );
  }

  Widget _topSearchBar(int count) {
    return Column(
      children: [
        Row(
          children: [
            _smallTopButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xF21A1A1A),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _tuKhoa = value;
                      _diaDiemDangChon = null;
                    });
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm địa điểm trên bản đồ',
                    hintStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white70,
                    ),
                    suffixIcon: _tuKhoa.trim().isEmpty
                        ? null
                        : InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _tuKhoa = '';
                                _diaDiemDangChon = null;
                              });
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xE61A1A1A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count địa điểm du lịch',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeInfoCard(_MapPlace place) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xF21A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _markerColor(place).withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _markerColor(place).withOpacity(0.45)),
            ),
            child: Icon(
              _markerIcon(place),
              color: _markerColor(place),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place.fullAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 17,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      place.avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${place.totalReviews} đánh giá',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _blueSmallButton(
                        text: 'Chi tiết',
                        icon: Icons.info_outline_rounded,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.placeDetail,
                            arguments: place.id,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _blueSmallButton(
                        text: 'Đường đi',
                        icon: Icons.directions_rounded,
                        onTap: () => _moDuongDiBangGoogleMaps(place),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blueSmallButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallTopButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xF21A1A1A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _roundMapButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xF21A1A1A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 23),
      ),
    );
  }

  Widget _loadingBox() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.18),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _errorBox() {
    return Positioned(
      left: 18,
      right: 18,
      top: 120,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xF21A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 38,
            ),
            const SizedBox(height: 10),
            const Text(
              'Không tải được bản đồ địa điểm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _loi ?? 'Lỗi không xác định',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _blueSmallButton(
              text: 'Thử lại',
              icon: Icons.refresh_rounded,
              onTap: _taiDiaDiemLenBanDo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyBox() {
    return Positioned(
      left: 18,
      right: 18,
      top: 120,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xF21A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.location_off_rounded, color: Colors.white, size: 38),
            SizedBox(height: 10),
            Text(
              'Chưa có địa điểm nào có tọa độ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Kiểm tra lại cột latitude và longitude trong bảng places.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _diDenViTriCuaToi() async {
    final position = await _layViTriHienTai();
    if (position == null) return;

    _mapController.move(LatLng(position.latitude, position.longitude), 15);

    _showMessage('Đã chuyển đến vị trí hiện tại của bạn');
  }

  // NOTE SỬA:
  // Sửa mở đường đi bằng Google Maps.
  // Cách 1 dùng google.navigation để ép Google Maps mở điều hướng tới điểm đến.
  // Cách 2 fallback dùng Google Maps URL có origin là GPS hiện tại và destination là địa điểm.
  Future<void> _moDuongDiBangGoogleMaps(_MapPlace place) async {
    if (place.latitude == null || place.longitude == null) {
      _showMessage('Địa điểm này chưa có tọa độ');
      return;
    }

    final position = await _layViTriHienTai();
    if (position == null) return;

    final destinationLat = place.latitude!;
    final destinationLng = place.longitude!;

    final navigationUri = Uri.parse(
      'google.navigation:q=$destinationLat,$destinationLng&mode=d',
    );

    try {
      final openedNavigation = await launchUrl(
        navigationUri,
        mode: LaunchMode.externalApplication,
      );

      if (openedNavigation) return;
    } catch (_) {
      // Nếu máy không hỗ trợ google.navigation thì chạy fallback bên dưới.
    }

    final directionsUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': '${position.latitude},${position.longitude}',
      'destination': '$destinationLat,$destinationLng',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });

    final openedDirections = await launchUrl(
      directionsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!openedDirections) {
      _showMessage('Không mở được Google Maps');
    }
  }

  Future<Position?> _layViTriHienTai() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Bạn cần bật GPS để lấy vị trí hiện tại');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage('Bạn chưa cấp quyền vị trí');
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Quyền vị trí đang bị chặn. Hãy mở cài đặt để cấp quyền lại.',
      );
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      _showMessage('Không lấy được vị trí hiện tại');
      return null;
    }
  }

  Color _markerColor(_MapPlace place) {
    final text = _normalize('${place.name} ${place.keywords ?? ''}');

    if (text.contains('bien') ||
        text.contains('dao') ||
        text.contains('song')) {
      return const Color(0xFF13A8FF);
    }

    if (text.contains('nui') ||
        text.contains('rung') ||
        text.contains('thien nhien') ||
        text.contains('trekking')) {
      return const Color(0xFF24C46B);
    }

    if (text.contains('cho') ||
        text.contains('am thuc') ||
        text.contains('an uong')) {
      return const Color(0xFFFF9F1C);
    }

    if (text.contains('lich su') ||
        text.contains('di tich') ||
        text.contains('van hoa')) {
      return const Color(0xFF8E6CFF);
    }

    return AppColors.primary;
  }

  IconData _markerIcon(_MapPlace place) {
    final text = _normalize('${place.name} ${place.keywords ?? ''}');

    if (text.contains('bien') || text.contains('dao')) {
      return Icons.beach_access_rounded;
    }

    if (text.contains('nui') ||
        text.contains('rung') ||
        text.contains('thien nhien') ||
        text.contains('trekking')) {
      return Icons.terrain_rounded;
    }

    if (text.contains('cho') ||
        text.contains('am thuc') ||
        text.contains('an uong')) {
      return Icons.restaurant_rounded;
    }

    if (text.contains('lich su') ||
        text.contains('di tich') ||
        text.contains('van hoa')) {
      return Icons.account_balance_rounded;
    }

    return Icons.place_rounded;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _normalize(String input) {
    var text = input.toLowerCase();

    const replacements = <String, String>{
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };

    replacements.forEach((plain, accents) {
      for (final char in accents.split('')) {
        text = text.replaceAll(char, plain);
      }
    });

    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }
}

class _MapPlace {
  final int id;
  final int? categoryId;
  final String name;
  final String province;
  final String? district;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? openingHours;
  final double price;
  final double avgRating;
  final int totalReviews;
  final int totalSaves;
  final String? keywords;
  final String? description;
  final String status;

  const _MapPlace({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.province,
    required this.district,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.openingHours,
    required this.price,
    required this.avgRating,
    required this.totalReviews,
    required this.totalSaves,
    required this.keywords,
    required this.description,
    required this.status,
  });

  bool get hasLatLng => latitude != null && longitude != null;

  String get fullAddress {
    final parts = [
      address,
      district,
      province,
    ].where((item) => item != null && item.trim().isNotEmpty).cast<String>();

    return parts.join(', ');
  }

  factory _MapPlace.fromJson(Map<String, dynamic> json) {
    return _MapPlace(
      id: _toInt(json['id']),
      categoryId: _toNullableInt(json['category_id']),
      name: (json['name'] ?? '').toString(),
      province: (json['province'] ?? '').toString(),
      district: json['district']?.toString(),
      address: json['address']?.toString(),
      latitude: _toNullableDouble(json['latitude']),
      longitude: _toNullableDouble(json['longitude']),
      openingHours: json['opening_hours']?.toString(),
      price: _toDouble(json['price']),
      avgRating: _toDouble(json['avg_rating']),
      totalReviews: _toInt(json['total_reviews']),
      totalSaves: _toInt(json['total_saves']),
      keywords: json['keywords']?.toString(),
      description: json['description']?.toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
