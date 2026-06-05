import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';

/// NOTE SỬA:
/// Trang bản đồ địa điểm du lịch.
/// Luồng:
/// - places.user_id = null: địa điểm chung, tất cả user đều thấy.
/// - places.user_id = currentUser.id: địa điểm riêng của user hiện tại.
/// - Địa điểm chung chỉ có Chi tiết / Đường đi.
/// - Địa điểm riêng có Chi tiết / Đường đi / Sửa / Xóa / Share.
/// - Thêm/sửa địa điểm dùng chính bản đồ này để ghim vị trí.
/// - Không nhập tay latitude/longitude.
/// - Ảnh địa điểm chọn từ thư viện và upload lên Supabase Storage.
/// - Bấm vào ô "x địa điểm" sẽ mở danh sách địa điểm đang hiện trên map.
class TrangBanDoDiaDiemPage extends StatefulWidget {
  const TrangBanDoDiaDiemPage({super.key});

  @override
  State<TrangBanDoDiaDiemPage> createState() => _TrangBanDoDiaDiemPageState();
}

class _TrangBanDoDiaDiemPageState extends State<TrangBanDoDiaDiemPage> {
  static const String _placeSelectColumns =
      'id, category_id, user_id, copied_from_place_id, name, province, district, address, latitude, longitude, opening_hours, price, avg_rating, total_reviews, total_saves, keywords, description, cover_image, status';

  final SupabaseClient _supabase = Supabase.instance.client;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final LatLng _vietnamCenter = const LatLng(14.0583, 108.2772);

  List<_MapPlace> _tatCaDiaDiem = [];
  _MapPlace? _diaDiemDangChon;

  int? _selectedPlaceIdFromDetail;
  bool _daDocArgument = false;

  bool _dangGhimViTri = false;
  bool _dangGhimDeSua = false;
  LatLng? _viTriDangGhim;
  _MapPlace? _diaDiemDangSua;

  bool _dangTai = true;
  String? _loi;
  String _tuKhoa = '';

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _taiDiaDiemLenBanDo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

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
      final mineA = a.isMine(_currentUserId) ? 1 : 0;
      final mineB = b.isMine(_currentUserId) ? 1 : 0;
      final ownerCompare = mineB.compareTo(mineA);
      if (ownerCompare != 0) return ownerCompare;

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
      final userId = _currentUserId;

      final response = userId == null
          ? await _supabase
                .from('places')
                .select(_placeSelectColumns)
                .eq('status', 'active')
                .filter('user_id', 'is', null)
                .order('total_saves', ascending: false)
          : await _supabase
                .from('places')
                .select(_placeSelectColumns)
                .eq('status', 'active')
                .or('user_id.is.null,user_id.eq.$userId')
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

      if (data.isNotEmpty && !_dangGhimViTri) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

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
                onTap: (_, point) {
                  if (_dangGhimViTri) {
                    setState(() {
                      _viTriDangGhim = point;
                    });
                    return;
                  }

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
                MarkerLayer(
                  markers: [
                    ...places.map(_buildPlaceMarker),
                    if (_dangGhimViTri && _viTriDangGhim != null)
                      Marker(
                        width: 62,
                        height: 62,
                        point: _viTriDangGhim!,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 58,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            Positioned(
              left: 14,
              right: 14,
              top: 12,
              child: _topSearchBar(places),
            ),

            Positioned(
              right: 14,
              bottom: _dangGhimViTri
                  ? 170
                  : _diaDiemDangChon == null
                  ? 24
                  : 236,
              child: Column(
                children: [
                  if (!_dangGhimViTri)
                    _roundMapButton(
                      icon: Icons.add_location_alt_rounded,
                      onTap: _batDauThemDiaDiemBangGhim,
                    ),
                  if (!_dangGhimViTri) const SizedBox(height: 10),
                  _roundMapButton(
                    icon: Icons.my_location_rounded,
                    onTap: _dangGhimViTri
                        ? _ghimTheoViTriHienTai
                        : _diDenViTriCuaToi,
                  ),
                  const SizedBox(height: 10),
                  if (!_dangGhimViTri)
                    _roundMapButton(
                      icon: Icons.refresh_rounded,
                      onTap: _taiDiaDiemLenBanDo,
                    ),
                ],
              ),
            ),

            if (_dangTai) _loadingBox(),

            if (!_dangTai && _loi != null) _errorBox(),

            if (!_dangTai && _loi == null && places.isEmpty && !_dangGhimViTri)
              _emptyBox(),

            if (_diaDiemDangChon != null && !_dangGhimViTri)
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: _placeInfoCard(_diaDiemDangChon!),
              ),

            if (_dangGhimViTri) _pinLocationPanel(),
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
          if (_dangGhimViTri) return;

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

  Widget _topSearchBar(List<_MapPlace> places) {
    if (_dangGhimViTri) {
      return Row(
        children: [
          _smallTopButton(icon: Icons.close_rounded, onTap: _huyGhimViTri),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xF21A1A1A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                _dangGhimDeSua ? 'Ghim vị trí mới' : 'Ghim vị trí địa điểm',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }

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

        // NOTE SỬA:
        // Bấm vào ô số lượng địa điểm sẽ mở danh sách địa điểm.
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: places.isEmpty ? null : () => _moDanhSachDiaDiem(places),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xE61A1A1A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: places.isEmpty
                      ? Colors.transparent
                      : AppColors.primary.withOpacity(0.55),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${places.length} địa điểm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (places.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // NOTE SỬA:
  // Bottom sheet danh sách địa điểm đang hiện trên map.
  // Bấm item nào thì zoom tới item đó và hiện card chi tiết.
  Future<void> _moDanhSachDiaDiem(List<_MapPlace> places) async {
    if (places.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.38,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Danh sách địa điểm (${places.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.pop(sheetContext),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: places.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final place = places[index];
                          final isMine = place.isMine(_currentUserId);

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _chonDiaDiemTuDanhSach(place);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF202020),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  _placeImageOrIcon(
                                    place,
                                    size: 58,
                                    iconSize: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                place.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            _placeTypeBadge(
                                              isMine ? 'Của tôi' : 'Chung',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
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
                                              size: 16,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              place.avgRating.toStringAsFixed(
                                                1,
                                              ),
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
                                                color: Colors.white54,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _chonDiaDiemTuDanhSach(_MapPlace place) {
    FocusScope.of(context).unfocus();

    setState(() {
      _diaDiemDangChon = place;
    });

    _mapController.move(place.latLng, 15);
  }

  Widget _pinLocationPanel() {
    final point = _viTriDangGhim;

    return Positioned(
      left: 14,
      right: 14,
      bottom: 16,
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chạm lên bản đồ để đặt ghim vị trí',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              point == null
                  ? 'Chưa chọn vị trí'
                  : '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _outlineActionButton(
                    text: 'Hủy',
                    icon: Icons.close_rounded,
                    onTap: _huyGhimViTri,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _solidActionButton(
                    text: 'Tiếp tục',
                    icon: Icons.check_rounded,
                    onTap: _tiepTucSauKhiGhim,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeInfoCard(_MapPlace place) {
    final isMine = place.isMine(_currentUserId);

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
          _placeImageOrIcon(place, size: 62, iconSize: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _placeTypeBadge(isMine ? 'Của tôi' : 'Chung'),
                  ],
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _smallActionButton(
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
                    _smallActionButton(
                      text: 'Đường đi',
                      icon: Icons.directions_rounded,
                      onTap: () => _moDuongDiBangGoogleMaps(place),
                    ),
                    if (isMine) ...[
                      _smallActionButton(
                        text: 'Sửa',
                        icon: Icons.edit_location_alt_rounded,
                        onTap: () => _batDauSuaDiaDiemBangGhim(place),
                      ),
                      _smallActionButton(
                        text: 'Xóa',
                        icon: Icons.delete_outline_rounded,
                        danger: true,
                        onTap: () => _xacNhanXoaDiaDiem(place),
                      ),
                      _smallActionButton(
                        text: 'Share',
                        icon: Icons.ios_share_rounded,
                        onTap: () => _moSheetChiaSe(place),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeImageOrIcon(
    _MapPlace place, {
    required double size,
    required double iconSize,
  }) {
    final imageUrl = place.coverImage;

    if (imageUrl != null && imageUrl.trim().startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _placeIconBox(place, size: size, iconSize: iconSize),
        ),
      );
    }

    return _placeIconBox(place, size: size, iconSize: iconSize);
  }

  Widget _placeIconBox(
    _MapPlace place, {
    required double size,
    required double iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _markerColor(place).withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _markerColor(place).withOpacity(0.45)),
      ),
      child: Icon(
        place.isMine(_currentUserId)
            ? Icons.person_pin_circle_rounded
            : _markerIcon(place),
        color: _markerColor(place),
        size: iconSize,
      ),
    );
  }

  Widget _placeTypeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: text == 'Của tôi'
            ? AppColors.primaryDark
            : const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _smallActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: danger ? const Color(0xFF5A2424) : AppColors.primaryDark,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _solidActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
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
            _smallActionButton(
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
        child: Column(
          children: [
            const Icon(
              Icons.location_off_rounded,
              color: Colors.white,
              size: 38,
            ),
            const SizedBox(height: 10),
            const Text(
              'Chưa có địa điểm nào có tọa độ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bạn có thể bấm nút + để thêm địa điểm riêng lên bản đồ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _smallActionButton(
              text: 'Thêm địa điểm',
              icon: Icons.add_location_alt_rounded,
              onTap: _batDauThemDiaDiemBangGhim,
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

  Future<void> _batDauThemDiaDiemBangGhim() async {
    final userId = _currentUserId;

    if (userId == null) {
      _showMessage('Bạn cần đăng nhập để thêm địa điểm riêng');
      return;
    }

    final startPoint = _diaDiemDangChon?.latLng ?? _vietnamCenter;

    setState(() {
      _dangGhimViTri = true;
      _dangGhimDeSua = false;
      _diaDiemDangSua = null;
      _diaDiemDangChon = null;
      _viTriDangGhim = startPoint;
    });

    _mapController.move(startPoint, 15);
  }

  Future<void> _batDauSuaDiaDiemBangGhim(_MapPlace place) async {
    if (!place.isMine(_currentUserId)) {
      _showMessage('Bạn chỉ được sửa địa điểm của mình');
      return;
    }

    setState(() {
      _dangGhimViTri = true;
      _dangGhimDeSua = true;
      _diaDiemDangSua = place;
      _diaDiemDangChon = null;
      _viTriDangGhim = place.latLng;
    });

    _mapController.move(place.latLng, 15);
  }

  void _huyGhimViTri() {
    setState(() {
      _dangGhimViTri = false;
      _dangGhimDeSua = false;
      _viTriDangGhim = null;
      _diaDiemDangSua = null;
    });
  }

  Future<void> _ghimTheoViTriHienTai() async {
    final position = await _layViTriHienTai();
    if (position == null) return;

    final point = LatLng(position.latitude, position.longitude);

    setState(() {
      _viTriDangGhim = point;
    });

    _mapController.move(point, 16);
  }

  Future<void> _tiepTucSauKhiGhim() async {
    final point = _viTriDangGhim;

    if (point == null) {
      _showMessage('Bạn cần chọn vị trí trên bản đồ');
      return;
    }

    await _moFormThemSuaDiaDiem(
      place: _dangGhimDeSua ? _diaDiemDangSua : null,
      selectedLocation: point,
    );
  }

  Future<void> _moFormThemSuaDiaDiem({
    _MapPlace? place,
    required LatLng selectedLocation,
  }) async {
    final userId = _currentUserId;

    if (userId == null) {
      _showMessage('Bạn cần đăng nhập');
      return;
    }

    final isEdit = place != null;

    final nameController = TextEditingController(text: place?.name ?? '');
    final provinceController = TextEditingController(
      text: place?.province ?? '',
    );
    final districtController = TextEditingController(
      text: place?.district ?? '',
    );
    final addressController = TextEditingController(text: place?.address ?? '');
    final descriptionController = TextEditingController(
      text: place?.description ?? '',
    );
    final keywordsController = TextEditingController(
      text: place?.keywords ?? '',
    );
    final priceController = TextEditingController(
      text: place == null || place.price <= 0
          ? ''
          : place.price.toStringAsFixed(0),
    );

    XFile? anhMoi;
    String? anhCu = place?.coverImage;
    bool xoaAnhCu = false;
    bool dangLuu = false;
    bool luuThanhCong = false;
    bool anhKhongLuuDuoc = false;
    String? thongBaoSauKhiLuu;
    var selectedMarkerPreset = _markerPresetFromKeywords(place?.keywords);

    if (!isEdit && addressController.text.trim().isEmpty) {
      final suggestedAddress = await _goiYDiaChiTuToaDo(selectedLocation);
      if (!mounted) return;

      if (suggestedAddress != null) {
        addressController.text = suggestedAddress.address ?? '';
        provinceController.text = suggestedAddress.province ?? '';
        districtController.text = suggestedAddress.district ?? '';
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            Future<void> chonAnhTuThuVien() async {
              try {
                final picked = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 82,
                  maxWidth: 1600,
                );

                if (picked == null) return;

                modalSetState(() {
                  anhMoi = picked;
                  xoaAnhCu = false;
                });
              } catch (e) {
                _showMessage('Không chọn được ảnh');
              }
            }

            Future<void> luuDiaDiem() async {
              final name = nameController.text.trim();
              final province = provinceController.text.trim();

              if (name.isEmpty) {
                _showMessage('Bạn cần nhập tên địa điểm');
                return;
              }

              if (province.isEmpty) {
                _showMessage('Bạn cần nhập tỉnh/thành');
                return;
              }

              if (dangLuu) return;

              FocusManager.instance.primaryFocus?.unfocus();

              modalSetState(() {
                dangLuu = true;
              });

              try {
                final rawPrice = priceController.text
                    .replaceAll('.', '')
                    .replaceAll(',', '')
                    .replaceAll('đ', '')
                    .trim();

                final price = double.tryParse(rawPrice) ?? 0;

                String? coverImage;

                if (anhMoi != null) {
                  coverImage = await _uploadAnhDiaDiem(anhMoi!, userId);
                  anhKhongLuuDuoc = coverImage == null;
                } else if (xoaAnhCu) {
                  coverImage = null;
                } else {
                  coverImage = anhCu;
                }

                final mergedKeywords = _tronTuKhoaVoiBieuTuong(
                  keywordsController.text.trim(),
                  selectedMarkerPreset,
                );

                final data = <String, dynamic>{
                  'name': name,
                  'province': province,
                  'district': districtController.text.trim().isEmpty
                      ? null
                      : districtController.text.trim(),
                  'address': addressController.text.trim().isEmpty
                      ? null
                      : addressController.text.trim(),
                  'description': descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  'keywords': mergedKeywords.isEmpty ? null : mergedKeywords,
                  'price': price,
                  'cover_image': coverImage,
                  'latitude': selectedLocation.latitude,
                  'longitude': selectedLocation.longitude,
                  'status': 'active',
                  'user_id': userId,
                  'updated_at': DateTime.now().toIso8601String(),
                };

                if (isEdit) {
                  final updated = await _supabase
                      .from('places')
                      .update(data)
                      .eq('id', place.id)
                      .eq('user_id', userId)
                      .select(_placeSelectColumns)
                      .maybeSingle();

                  if (updated == null) {
                    throw Exception(
                      'Không cập nhật được địa điểm. Hãy kiểm tra quyền sở hữu địa điểm này.',
                    );
                  }

                  if (!mounted || !sheetContext.mounted) return;

                  luuThanhCong = true;
                  thongBaoSauKhiLuu = anhKhongLuuDuoc
                      ? 'Đã cập nhật địa điểm, nhưng ảnh chưa lưu được'
                      : 'Đã cập nhật địa điểm';
                  Navigator.pop(sheetContext);
                  return;
                } else {
                  data.addAll({
                    'category_id': 1,
                    'avg_rating': 0,
                    'total_reviews': 0,
                    'total_saves': 0,
                    'copied_from_place_id': null,
                  });

                  await _supabase.from('places').insert(data);

                  if (!mounted || !sheetContext.mounted) return;

                  luuThanhCong = true;
                  thongBaoSauKhiLuu = anhKhongLuuDuoc
                      ? 'Đã thêm địa điểm, nhưng ảnh chưa lưu được'
                      : 'Đã thêm địa điểm vào bản đồ của bạn';
                  Navigator.pop(sheetContext);
                  return;
                }
              } catch (e) {
                _showMessage(e.toString().replaceFirst('Exception: ', ''));
              } finally {
                if (!luuThanhCong) {
                  try {
                    if (context.mounted) {
                      modalSetState(() {
                        dangLuu = false;
                      });
                    }
                  } catch (_) {}
                }
              }
            }

            return PopScope(
              canPop: !dangLuu,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 18,
                    right: 18,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetTitle(
                          isEdit ? 'Sửa địa điểm' : 'Thêm địa điểm riêng',
                          onClose: dangLuu
                              ? () {}
                              : () => Navigator.pop(sheetContext),
                        ),
                        const SizedBox(height: 14),
                        _imagePickerBox(
                          anhMoi: anhMoi,
                          anhCu: xoaAnhCu ? null : anhCu,
                          onPick: chonAnhTuThuVien,
                          onRemove: () {
                            modalSetState(() {
                              anhMoi = null;
                              xoaAnhCu = true;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: nameController,
                          label: 'Tên địa điểm',
                          hint: 'VD: Quán cafe view đẹp',
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          controller: provinceController,
                          label: 'Tỉnh/thành',
                          hint: 'VD: Lâm Đồng',
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          controller: districtController,
                          label: 'Quận/huyện',
                          hint: 'VD: Đà Lạt',
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          controller: addressController,
                          label: 'Địa chỉ',
                          hint: 'VD: Đường ABC, phường XYZ',
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          controller: descriptionController,
                          label: 'Mô tả',
                          hint: 'Ghi chú ngắn về địa điểm',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          controller: keywordsController,
                          label: 'Từ khóa',
                          hint: 'VD: cafe, check-in, view đẹp',
                        ),
                        const SizedBox(height: 10),
                        _markerPresetPicker(
                          selected: selectedMarkerPreset,
                          onChanged: (preset) {
                            modalSetState(() {
                              selectedMarkerPreset = preset;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          controller: priceController,
                          label: 'Giá tham khảo',
                          hint: 'VD: 50000',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF202020),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: dangLuu ? null : luuDiaDiem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              dangLuu
                                  ? 'Đang lưu...'
                                  : isEdit
                                  ? 'Cập nhật địa điểm'
                                  : 'Thêm địa điểm',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (luuThanhCong && mounted) {
      setState(() {
        _dangGhimViTri = false;
        _dangGhimDeSua = false;
        _viTriDangGhim = null;
        _diaDiemDangSua = null;
        _diaDiemDangChon = null;
      });

      await _taiDiaDiemLenBanDo();

      if (mounted && thongBaoSauKhiLuu != null) {
        _showMessage(thongBaoSauKhiLuu!);
      }
    }

    nameController.dispose();
    provinceController.dispose();
    districtController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    keywordsController.dispose();
    priceController.dispose();
  }

  Future<_SuggestedAddress?> _goiYDiaChiTuToaDo(LatLng point) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts =
          [
                place.street,
                place.subLocality,
                place.locality,
                place.subAdministrativeArea,
              ]
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList();

      final province = (place.administrativeArea ?? '').trim();
      final district = (place.locality ?? place.subAdministrativeArea ?? '')
          .trim();

      return _SuggestedAddress(
        address: parts.isEmpty ? null : parts.join(', '),
        province: province.isEmpty ? null : province,
        district: district.isEmpty ? null : district,
      );
    } catch (_) {
      return null;
    }
  }

  _MarkerPreset _markerPresetFromKeywords(String? keywords) {
    final text = _normalize(keywords ?? '');

    for (final preset in _markerPresets) {
      if (text.contains(_normalize(preset.keyword))) {
        return preset;
      }
    }

    return _markerPresets.first;
  }

  String _tronTuKhoaVoiBieuTuong(
    String rawKeywords,
    _MarkerPreset selectedPreset,
  ) {
    final parts = rawKeywords
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .where((item) {
          final normalized = _normalize(item);
          return !_markerPresets.any(
            (preset) => normalized == _normalize(preset.keyword),
          );
        })
        .toList();

    parts.insert(0, selectedPreset.keyword);
    return parts.toSet().join(', ');
  }

  Widget _markerPresetPicker({
    required _MarkerPreset selected,
    required ValueChanged<_MarkerPreset> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Biểu tượng',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _markerPresets.map((preset) {
            final isSelected = preset.keyword == selected.keyword;

            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(preset),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.18)
                      : const Color(0xFF202020),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      preset.icon,
                      color: isSelected ? AppColors.primary : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      preset.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sheetTitle(String title, {required VoidCallback onClose}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onClose,
          child: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _imagePickerBox({
    required XFile? anhMoi,
    required String? anhCu,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    Widget preview;

    if (anhMoi != null) {
      preview = Image.file(
        File(anhMoi.path),
        width: double.infinity,
        height: 155,
        fit: BoxFit.cover,
      );
    } else if (anhCu != null && anhCu.trim().startsWith('http')) {
      preview = Image.network(
        anhCu,
        width: double.infinity,
        height: 155,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _emptyImagePreview(),
      );
    } else {
      preview = _emptyImagePreview();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: preview,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _solidActionButton(
                    text: 'Chọn ảnh',
                    icon: Icons.photo_library_rounded,
                    onTap: onPick,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _outlineActionButton(
                    text: 'Xóa ảnh',
                    icon: Icons.delete_outline_rounded,
                    onTap: onRemove,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyImagePreview() {
    return Container(
      width: double.infinity,
      height: 155,
      color: const Color(0xFF2A2A2A),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: Colors.white60,
            size: 42,
          ),
          SizedBox(height: 8),
          Text(
            'Chọn ảnh từ thư viện',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: const Color(0xFF242424),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _uploadAnhDiaDiem(XFile image, String userId) async {
    final extension = _layDuoiFileAnh(image);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}.$extension';
    final filePath = '$userId/$fileName';

    final contentType = _contentTypeTheoDuoiFile(extension);

    try {
      await _supabase.storage
          .from('place-images')
          .upload(
            filePath,
            File(image.path),
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: contentType,
            ),
          );
    } on StorageException catch (e) {
      if (e.statusCode == '404' || e.message.contains('Bucket not found')) {
        return null;
      }

      rethrow;
    }

    return _supabase.storage.from('place-images').getPublicUrl(filePath);
  }

  String _layDuoiFileAnh(XFile image) {
    final name = image.name.toLowerCase();

    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    if (name.endsWith('.jpeg')) return 'jpeg';
    if (name.endsWith('.jpg')) return 'jpg';

    final path = image.path.toLowerCase();

    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.webp')) return 'webp';
    if (path.endsWith('.jpeg')) return 'jpeg';

    return 'jpg';
  }

  String _contentTypeTheoDuoiFile(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _xacNhanXoaDiaDiem(_MapPlace place) async {
    if (!place.isMine(_currentUserId)) {
      _showMessage('Bạn chỉ được xóa địa điểm của mình');
      return;
    }

    final dongY = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF202020),
          title: const Text(
            'Xóa địa điểm?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Bạn có chắc muốn xóa "${place.name}" khỏi bản đồ của mình không?',
            style: const TextStyle(color: Colors.white70, height: 1.3),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (dongY != true) return;

    try {
      final deleted = await _supabase
          .from('places')
          .update({
            'status': 'deleted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', place.id)
          .eq('user_id', _currentUserId!)
          .select('id')
          .maybeSingle();

      if (deleted == null) {
        throw Exception(
          'Không xóa được địa điểm. Chỉ địa điểm riêng của bạn mới được xóa.',
        );
      }

      if (!mounted) return;

      setState(() {
        _diaDiemDangChon = null;
      });

      _showMessage('Đã xóa địa điểm');
      await _taiDiaDiemLenBanDo();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _moSheetChiaSe(_MapPlace place) async {
    final userId = _currentUserId;

    if (userId == null) {
      _showMessage('Bạn cần đăng nhập để share địa điểm');
      return;
    }

    if (!place.isMine(userId)) {
      _showMessage('Chỉ được share địa điểm của bạn');
      return;
    }

    try {
      final friends = await _taiDanhSachBanBe();

      if (!mounted) return;

      if (friends.isEmpty) {
        _showMessage('Chưa có bạn bè để chia sẻ');
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF151515),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetTitle(
                    'Chia sẻ địa điểm',
                    onClose: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: friends.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Color(0xFF2C2C2C), height: 1),
                      itemBuilder: (context, index) {
                        final friend = friends[index];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryDark,
                            backgroundImage:
                                friend.avatarUrl != null &&
                                    friend.avatarUrl!.startsWith('http')
                                ? NetworkImage(friend.avatarUrl!)
                                : null,
                            child:
                                friend.avatarUrl == null ||
                                    !friend.avatarUrl!.startsWith('http')
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          title: Text(
                            friend.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            friend.emailOrUsername,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.send_rounded,
                            color: AppColors.primary,
                          ),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await _guiShareDiaDiem(place, friend);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<_FriendProfile>> _taiDanhSachBanBe() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final followRows = await _supabase
        .from('follows')
        .select('follower_id, following_id')
        .or('follower_id.eq.$userId,following_id.eq.$userId');

    final following = <String>{};
    final followers = <String>{};

    for (final row in followRows as List) {
      final map = Map<String, dynamic>.from(row);
      final followerId = map['follower_id']?.toString();
      final followingId = map['following_id']?.toString();

      if (followerId == userId && followingId != null) {
        following.add(followingId);
      }

      if (followingId == userId && followerId != null) {
        followers.add(followerId);
      }
    }

    final friendIds = following.intersection(followers).toList();

    if (friendIds.isEmpty) return [];

    final profileRows = await _supabase
        .from('profiles')
        .select()
        .inFilter('id', friendIds);

    return (profileRows as List)
        .map((json) => _FriendProfile.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> _guiShareDiaDiem(_MapPlace place, _FriendProfile friend) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final existing = await _supabase
          .from('place_shares')
          .select('id')
          .eq('place_id', place.id)
          .eq('from_user_id', userId)
          .eq('to_user_id', friend.id)
          .eq('status', 'pending')
          .maybeSingle();

      if (existing != null) {
        _showMessage('Bạn đã gửi địa điểm này cho ${friend.name} rồi');
        return;
      }

      await _supabase.from('place_shares').insert({
        'place_id': place.id,
        'from_user_id': userId,
        'to_user_id': friend.id,
        'status': 'pending',
      });

      _showMessage('Đã gửi chia sẻ cho ${friend.name}');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

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
    } catch (_) {}

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
    if (place.isMine(_currentUserId)) {
      return AppColors.primary;
    }

    final text = _normalize('${place.name} ${place.keywords ?? ''}');

    if (text.contains('cafe') ||
        text.contains('ca phe') ||
        text.contains('check in')) {
      return AppColors.primary;
    }

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
        text.contains('nha hang') ||
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

    if (text.contains('cafe') || text.contains('ca phe')) {
      return Icons.local_cafe_rounded;
    }

    if (text.contains('check in')) {
      return Icons.photo_camera_rounded;
    }

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
        text.contains('nha hang') ||
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

const List<_MarkerPreset> _markerPresets = [
  _MarkerPreset(label: 'Cafe', keyword: 'cafe', icon: Icons.local_cafe_rounded),
  _MarkerPreset(
    label: 'Ăn uống',
    keyword: 'ăn uống',
    icon: Icons.restaurant_rounded,
  ),
  _MarkerPreset(
    label: 'Check-in',
    keyword: 'check-in',
    icon: Icons.photo_camera_rounded,
  ),
  _MarkerPreset(
    label: 'Thiên nhiên',
    keyword: 'thiên nhiên',
    icon: Icons.terrain_rounded,
  ),
  _MarkerPreset(
    label: 'Biển/đảo',
    keyword: 'biển đảo',
    icon: Icons.beach_access_rounded,
  ),
  _MarkerPreset(
    label: 'Văn hóa',
    keyword: 'văn hóa',
    icon: Icons.account_balance_rounded,
  ),
  _MarkerPreset(
    label: 'Khác',
    keyword: 'địa điểm riêng',
    icon: Icons.place_rounded,
  ),
];

class _MarkerPreset {
  final String label;
  final String keyword;
  final IconData icon;

  const _MarkerPreset({
    required this.label,
    required this.keyword,
    required this.icon,
  });
}

class _SuggestedAddress {
  final String? address;
  final String? province;
  final String? district;

  const _SuggestedAddress({this.address, this.province, this.district});
}

class _MapPlace {
  final int id;
  final int? categoryId;
  final String? userId;
  final int? copiedFromPlaceId;
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
  final String? coverImage;
  final String status;

  const _MapPlace({
    required this.id,
    required this.categoryId,
    required this.userId,
    required this.copiedFromPlaceId,
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
    required this.coverImage,
    required this.status,
  });

  bool get hasLatLng => latitude != null && longitude != null;

  bool get isPublic => userId == null || userId!.trim().isEmpty;

  bool isMine(String? currentUserId) {
    if (currentUserId == null) return false;
    return userId?.trim() == currentUserId.trim();
  }

  LatLng get latLng => LatLng(latitude!, longitude!);

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
      userId: json['user_id']?.toString(),
      copiedFromPlaceId: _toNullableInt(json['copied_from_place_id']),
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
      coverImage: json['cover_image']?.toString(),
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

class _FriendProfile {
  final String id;
  final String name;
  final String? username;
  final String? email;
  final String? avatarUrl;

  const _FriendProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.avatarUrl,
  });

  String get emailOrUsername {
    if (username != null && username!.trim().isNotEmpty) {
      return '@$username';
    }

    if (email != null && email!.trim().isNotEmpty) {
      return email!;
    }

    return 'Bạn bè';
  }

  factory _FriendProfile.fromJson(Map<String, dynamic> json) {
    final name =
        json['full_name'] ??
        json['display_name'] ??
        json['name'] ??
        json['username'] ??
        json['email'] ??
        'Người dùng';

    return _FriendProfile(
      id: json['id'].toString(),
      name: name.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}
