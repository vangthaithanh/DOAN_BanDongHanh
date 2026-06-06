import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/services/lich_trinh_nhom_service.dart';

class TrangChiTietLichTrinhNhomPage extends StatefulWidget {
  final int tripId;

  const TrangChiTietLichTrinhNhomPage({super.key, required this.tripId});

  @override
  State<TrangChiTietLichTrinhNhomPage> createState() =>
      _TrangChiTietLichTrinhNhomPageState();
}

class _TrangChiTietLichTrinhNhomPageState
    extends State<TrangChiTietLichTrinhNhomPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const Color darkGrey = Color(0xFF1D1D1D);
  static const Color fieldGrey = Color(0xFF242424);

  final LichTrinhNhomService _service = LichTrinhNhomService();
  late Future<TripGroupDetail> _future;
  int? _checkingStopId;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _service.capNhatViTriHienTai(silent: true);
  }

  void _reload() {
    _future = _service.layChiTietLichTrinhNhom(widget.tripId);
  }

  void _close() {
    Navigator.pop(context, _hasChanges);
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

  Future<void> _openEdit(TripGroupDetail detail) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.groupTripCreate,
      arguments: {'tripId': detail.group.id},
    );

    if (!mounted) return;

    if (changed == true) {
      _hasChanges = true;
      setState(_reload);
    }
  }

  Future<void> _deleteGroup(TripGroupDetail detail) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF202020),
          title: Text(
            'Xóa lịch trình nhóm?',
            style: _text(size: 18, weight: FontWeight.w800),
          ),
          content: Text(
            'Bạn có chắc muốn xóa "${detail.group.title}" không?',
            style: _text(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await _service.xoaLichTrinhNhom(detail.group.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _checkStop(TripStop stop) async {
    setState(() => _checkingStopId = stop.id);

    try {
      final result = await _service.kiemTraDiemDung(stop.id);

      if (!mounted) return;

      await _showCheckResult(result);

      if (!mounted) return;
      _hasChanges = true;
      setState(_reload);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _checkingStopId = null);
      }
    }
  }

  Future<void> _showCheckResult(TripStopCheckResult result) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  result.stop.title,
                  style: _text(size: 20, weight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đã tới: ${result.arrived.length}/${result.members.length} • Bán kính 300m',
                  style: _text(color: Colors.white60),
                ),
                const SizedBox(height: 18),
                _resultGroup('Đã tới', result.arrived, Colors.greenAccent),
                const SizedBox(height: 14),
                _resultGroup(
                  'Chưa tới',
                  result.notArrived,
                  Colors.orangeAccent,
                ),
                const SizedBox(height: 14),
                _resultGroup(
                  'Thiếu vị trí',
                  result.noLocation,
                  Colors.redAccent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _resultGroup(
    String title,
    List<TripStopMemberStatus> items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _text(weight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text('Không có', style: _text(color: Colors.white38))
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(weight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    item.statusText,
                    style: _text(size: 12, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openMemberMap(TripMember member) {
    Navigator.pushNamed(
      context,
      AppRoutes.groupTripMap,
      arguments: {'tripId': widget.tripId, 'focusUserId': member.userId},
    );
  }

  void _openStopMap(TripStop stop) {
    final placeId = stop.placeId;

    if (placeId != null && placeId > 0) {
      Navigator.pushNamed(
        context,
        AppRoutes.placeMap,
        arguments: {'selectedPlaceId': placeId},
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.map,
      arguments: {
        'lat': stop.latitude,
        'lng': stop.longitude,
        'ten': stop.title,
      },
    );
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _close();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: FutureBuilder<TripGroupDetail>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _error(snapshot.error!);
              }

              final detail = snapshot.data;
              if (detail == null) {
                return _error('Không tìm thấy lịch trình nhóm.');
              }

              return Column(
                children: [
                  _topBar(detail),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => setState(_reload),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          _summary(detail),
                          const SizedBox(height: 22),
                          _sectionTitle('Thành viên'),
                          ...detail.members.map(
                            (member) => _memberTile(detail, member),
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle('Điểm dừng'),
                          ...detail.stops.map(
                            (stop) => _stopCard(detail, stop),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar(TripGroupDetail detail) {
    final isOwner = detail.group.ownerId == _service.currentUserId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 12),
      child: Row(
        children: [
          InkWell(
            onTap: _close,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              detail.group.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _text(size: 19, weight: FontWeight.w800),
            ),
          ),
          if (isOwner)
            PopupMenuButton<String>(
              color: const Color(0xFF2B2B2B),
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  _openEdit(detail);
                } else if (value == 'delete') {
                  _deleteGroup(detail);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    'Sửa lịch trình',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Xóa lịch trình',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _summary(TripGroupDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.group.dateText,
            style: _text(size: 15, weight: FontWeight.w800, color: blue),
          ),
          if (detail.group.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(detail.group.description, style: _text(color: Colors.white70)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _miniInfo(
                Icons.groups_rounded,
                '${detail.members.length} thành viên',
              ),
              const SizedBox(width: 12),
              _miniInfo(Icons.place_outlined, '${detail.stops.length} điểm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: fieldGrey,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(width: 6),
          Text(text, style: _text(size: 12, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: _text(size: 18, weight: FontWeight.w800)),
    );
  }

  Widget _memberTile(TripGroupDetail detail, TripMember member) {
    final location = detail.locations[member.userId];
    final locationText = location == null
        ? 'Chưa có vị trí'
        : location.isStale
        ? 'Vị trí quá cũ • ${location.updatedText}'
        : location.updatedText;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: darkGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _avatar(member.avatarUrl, member.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(weight: FontWeight.w800),
                      ),
                    ),
                    if (member.isOwner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF183B59),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Chủ',
                          style: _text(
                            size: 10,
                            weight: FontWeight.w800,
                            color: blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  locationText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(size: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openMemberMap(member),
            icon: const Icon(Icons.map_outlined, color: blue),
          ),
        ],
      ),
    );
  }

  Widget _stopCard(TripGroupDetail detail, TripStop stop) {
    final checkins = detail.checkinsForStop(stop.id);
    final arrived = checkins.where((item) => item.isArrived).length;
    final checked = checkins.length;
    final summary = checked == 0
        ? 'Chưa kiểm tra'
        : 'Đã tới $arrived/${detail.members.length}';
    final isChecking = _checkingStopId == stop.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stop.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _text(size: 17, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            stop.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _text(size: 12, color: Colors.white54),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Có mặt: ${stop.timeText}',
                  style: _text(size: 13, weight: FontWeight.w800, color: blue),
                ),
              ),
              Text(summary, style: _text(size: 12, color: Colors.white60)),
            ],
          ),
          if (stop.note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(stop.note, style: _text(color: Colors.white60)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => _openStopMap(stop),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_rounded, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Đường đi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(weight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: isChecking ? null : () => _checkStop(stop),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      disabledBackgroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Center(
                      child: isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Kiểm tra',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: _text(weight: FontWeight.w800),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? url, String name) {
    final cleanUrl = url?.trim() ?? '';

    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFF303030),
      backgroundImage: cleanUrl.isEmpty ? null : NetworkImage(cleanUrl),
      child: cleanUrl.isEmpty
          ? Text(
              name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
              style: _text(weight: FontWeight.w800),
            )
          : null,
    );
  }

  Widget _error(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error.toString().replaceFirst('Exception: ', ''),
          textAlign: TextAlign.center,
          style: _text(color: Colors.white70),
        ),
      ),
    );
  }
}
