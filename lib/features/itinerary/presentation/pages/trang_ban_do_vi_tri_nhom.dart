import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
                  member.name,
                  style: _text(size: 20, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  location.isStale
                      ? 'Vị trí quá cũ • ${location.updatedText}'
                      : 'Cập nhật ${location.updatedText}',
                  style: _text(color: Colors.white60),
                ),
                const SizedBox(height: 6),
                Text(
                  '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  style: _text(size: 12, color: Colors.white38),
                ),
              ],
            ),
          ),
        );
      },
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
