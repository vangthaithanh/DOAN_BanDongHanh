import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/services/lich_trinh_nhom_service.dart';

class TrangLichTrinhNhomPage extends StatefulWidget {
  const TrangLichTrinhNhomPage({super.key});

  @override
  State<TrangLichTrinhNhomPage> createState() => _TrangLichTrinhNhomPageState();
}

class _TrangLichTrinhNhomPageState extends State<TrangLichTrinhNhomPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color lineGrey = Color(0xFF242424);

  final LichTrinhNhomService _service = LichTrinhNhomService();
  late Future<List<TripGroup>> _future;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _service.capNhatViTriHienTai(silent: true);
  }

  void _reload() {
    _future = _service.layDanhSachLichTrinhCuaToi();
  }

  void _markChangedAndReload() {
    setState(() {
      _hasChanges = true;
      _reload();
    });
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

  Future<void> _openCreate() async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.groupTripCreate,
    );

    if (!mounted) return;

    if (changed == true) {
      _markChangedAndReload();
    }
  }

  Future<void> _openDetail(int tripId) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.groupTripDetail,
      arguments: {'tripId': tripId},
    );

    if (!mounted) return;

    if (changed == true) {
      _markChangedAndReload();
    }
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
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(34, 12, 34, 20),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _openCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'Tạo lịch trình nhóm',
                  style: _text(size: 16, weight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: FutureBuilder<List<TripGroup>>(
            future: _future,
            builder: (context, snapshot) {
              return Column(
                children: [
                  _topBar(),
                  Expanded(child: _body(snapshot)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
      child: Row(
        children: [
          InkWell(
            onTap: _close,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: darkGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              'Lịch trình nhóm',
              textAlign: TextAlign.center,
              style: _text(size: 22, weight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _body(AsyncSnapshot<List<TripGroup>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            snapshot.error.toString().replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: _text(color: Colors.white70),
          ),
        ),
      );
    }

    final groups = snapshot.data ?? [];

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Text(
            'Tạo lịch trình nhóm để thêm bạn bè, điểm đến và kiểm tra ai đã tới.',
            textAlign: TextAlign.center,
            style: _text(
              size: 16,
              weight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(_reload),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 24),
        itemCount: groups.length,
        separatorBuilder: (context, index) =>
            const Divider(color: lineGrey, height: 1),
        itemBuilder: (context, index) => _groupTile(groups[index]),
      ),
    );
  }

  Widget _groupTile(TripGroup group) {
    return InkWell(
      onTap: () => _openDetail(group.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 24, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF183B59),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, color: blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(size: 21, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${group.memberCount} thành viên • ${group.stopCount} điểm đến',
                    style: _text(size: 13, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
