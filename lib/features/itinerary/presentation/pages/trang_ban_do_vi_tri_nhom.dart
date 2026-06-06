import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/services/lich_trinh_nhom_service.dart';

class TrangBanDoViTriNhomPage extends StatefulWidget {
  final int tripId;
  final String? focusUserId;

  const TrangBanDoViTriNhomPage({
    super.key,
    required this.tripId,
    this.focusUserId,
  });

  @override
  State<TrangBanDoViTriNhomPage> createState() =>
      _TrangBanDoViTriNhomPageState();
}

class _TrangBanDoViTriNhomPageState extends State<TrangBanDoViTriNhomPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const LatLng defaultCenter = LatLng(10.7769, 106.7009);

  final LichTrinhNhomService _service = LichTrinhNhomService();
  final MapController _mapController = MapController();
  Timer? _timer;
  TripGroupDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(move: true);
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _load(move: false),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({required bool move}) async {
    try {
      await _service.capNhatViTriHienTai(silent: true);
      final detail = await _service.layChiTietLichTrinhNhom(widget.tripId);

      if (!mounted) return;

      setState(() {
        _detail = detail;
        _loading = false;
      });

      if (move) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(_centerFor(detail), 15);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  TextStyle _text({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  LatLng _centerFor(TripGroupDetail detail) {
    final focusLocation = widget.focusUserId == null
        ? null
        : detail.locations[widget.focusUserId];

    if (focusLocation != null) {
      return LatLng(focusLocation.latitude, focusLocation.longitude);
    }

    if (detail.locations.isNotEmpty) {
      final first = detail.locations.values.first;
      return LatLng(first.latitude, first.longitude);
    }

    if (detail.stops.isNotEmpty) {
      final first = detail.stops.first;
      return LatLng(first.latitude, first.longitude);
    }

    return defaultCenter;
  }

  List<Marker> _markers(TripGroupDetail detail) {
    final markers = <Marker>[];

    for (final stop in detail.stops) {
      markers.add(
        Marker(
          point: LatLng(stop.latitude, stop.longitude),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _showStop(stop),
            child: const Icon(
              Icons.flag_circle,
              color: Colors.redAccent,
              size: 40,
            ),
          ),
        ),
      );
    }

    for (final member in detail.members) {
      final location = detail.locations[member.userId];
      if (location == null) continue;

      final focused = member.userId == widget.focusUserId;

      markers.add(
        Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 58,
          height: 58,
          child: GestureDetector(
            onTap: () => _showMember(member, location),
            child: Container(
              decoration: BoxDecoration(
                color: focused ? blue : const Color(0xFF2D2D2D),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                member.isOwner ? Icons.person_pin_circle : Icons.person_pin,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showMember(TripMember member, TripMemberLocation location) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xEE181818),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _memberAvatar(member),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _text(size: 16, weight: FontWeight.w900),
                              ),
                            ),
                            if (member.isOwner) _statusBadge('Chủ nhóm'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          location.isStale
                              ? 'Vị trí quá cũ • ${location.updatedText}'
                              : 'Cập nhật ${location.updatedText}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(
                            size: 12,
                            weight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(size: 11, color: Colors.white38),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _smallActionButton(
                              text: 'Đường đi',
                              icon: Icons.directions_rounded,
                              onTap: () {
                                Navigator.pop(context);
                                _moDuongDiToiThanhVien(location);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _moDuongDiToiThanhVien(TripMemberLocation location) async {
    final position = await _service.capNhatViTriHienTai();
    if (position == null) return;

    final destinationLat = location.latitude;
    final destinationLng = location.longitude;

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

    if (!openedDirections && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được Google Maps')),
      );
    }
  }

  Widget _memberAvatar(TripMember member) {
    final cleanUrl = member.avatarUrl?.trim() ?? '';

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: cleanUrl.isEmpty
            ? Icon(
                member.isOwner
                    ? Icons.person_pin_circle_rounded
                    : Icons.person_pin_rounded,
                color: AppColors.primary,
                size: 34,
              )
            : Image.network(
                cleanUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  member.isOwner
                      ? Icons.person_pin_circle_rounded
                      : Icons.person_pin_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
      ),
    );
  }

  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
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
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
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

  void _showStop(TripStop stop) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.title,
                  style: _text(size: 20, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(stop.address, style: _text(color: Colors.white60)),
                const SizedBox(height: 8),
                Text(
                  'Có mặt: ${stop.timeText}',
                  style: _text(color: blue, weight: FontWeight.w800),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          'Vị trí nhóm',
          style: _text(size: 19, weight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => _load(move: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? Center(
              child: Text(
                'Không tải được vị trí nhóm.',
                style: _text(color: Colors.white70),
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centerFor(detail),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gomate.app',
                ),
                MarkerLayer(markers: _markers(detail)),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
    );
  }
}
