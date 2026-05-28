import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/services/map_API.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _diaChiController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng _viTriHienTai = const LatLng(10.7769, 106.7009); // HCM mặc định
  bool _dangTai = false;

  Future<void> _timDiaChi() async {
    final text = _diaChiController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập địa chỉ trước đã')),
      );
      return;
    }

    setState(() {
      _dangTai = true;
    });

    final kq = await MapApi.timToaDo(text);

    setState(() {
      _dangTai = false;
    });

    if (kq == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy địa chỉ')),
      );
      return;
    }

    final latLng = LatLng(kq['lat']!, kq['lon']!);

    setState(() {
      _viTriHienTai = latLng;
    });

    _mapController.move(latLng, 16);
  }

  @override
  void dispose() {
    _diaChiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _diaChiController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập địa chỉ...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _timDiaChi(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _dangTai ? null : _timDiaChi,
                  child: _dangTai
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Tìm'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _viTriHienTai,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gomate.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _viTriHienTai,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        size: 45,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      // MapPage
      bottomNavigationBar: const AppBottomNav(activeTab: MainTab.map),
    );
  }
}