import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/services/lich_trinh_service.dart';

class TrangLichTrinhPage extends StatefulWidget {
  const TrangLichTrinhPage({super.key});

  @override
  State<TrangLichTrinhPage> createState() => _TrangLichTrinhPageState();
}

class _TrangLichTrinhPageState extends State<TrangLichTrinhPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color lineGrey = Color(0xFF242424);

  final LichTrinhService _service = LichTrinhService();

  late Future<List<LichTrinh>> _future;

  @override
  void initState() {
    super.initState();
    _load();
    _service.kiemTraLichTrinhDangGhimBangGps();
  }

  void _load() {
    _future = _service.layLichTrinhCuaToi();
  }

  void _reload() {
    setState(_load);
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
    final changed = await Navigator.pushNamed(context, AppRoutes.tripCreate);

    if (!mounted) return;

    if (changed == true) {
      _reload();
    }
  }

  Future<void> _openGroupTrips() async {
    final changed = await Navigator.pushNamed(context, AppRoutes.groupTripList);

    if (!mounted) return;

    if (changed == true) {
      _reload();
      Navigator.pop(context, true);
    }
  }

  Future<void> _openEdit(int itineraryId) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.tripCreate,
      arguments: {'itineraryId': itineraryId},
    );

    if (!mounted) return;

    if (changed == true) {
      _reload();
      Navigator.pop(context, true);
    }
  }

  Future<void> _togglePin(LichTrinh plan) async {
    try {
      await _service.doiTrangThaiGhim(
        itineraryId: plan.id,
        pinned: !plan.pinned,
      );
      _reload();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            plan.pinned
                ? 'Đã bỏ ghim lịch trình.'
                : 'Đã ghim lịch trình. GoMate sẽ kiểm tra GPS khi app đang mở.',
          ),
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deletePlan(LichTrinh plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF202020),
          title: const Text(
            'Xóa lịch trình?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Bạn có chắc muốn xóa "${plan.name}" không?',
            style: const TextStyle(color: Colors.white70),
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
      await _service.xoaLichTrinh(plan.id);
      _reload();

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                'Thêm lịch trình mới',
                style: _text(size: 16, weight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<LichTrinh>>(
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
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
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
              'Lịch trình',
              textAlign: TextAlign.center,
              style: _text(size: 22, weight: FontWeight.w800),
            ),
          ),
          InkWell(
            onTap: _openGroupTrips,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: darkGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, color: blue, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AsyncSnapshot<List<LichTrinh>> snapshot) {
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

    final plans = snapshot.data ?? [];

    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Text(
            'Hãy tạo lịch trình du lịch cá nhân của bạn',
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
      onRefresh: () async => _reload(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 24),
        itemCount: plans.length,
        separatorBuilder: (context, index) =>
            const Divider(color: lineGrey, height: 1),
        itemBuilder: (context, index) {
          return _planTile(plans[index]);
        },
      ),
    );
  }

  Widget _planTile(LichTrinh plan) {
    return InkWell(
      onTap: () => _openEdit(plan.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(50, 22, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          plan.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(size: 24, weight: FontWeight.w800),
                        ),
                      ),
                      if (plan.pinned) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.push_pin, color: blue, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.ngayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      size: 15,
                      weight: FontWeight.w700,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.routeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(size: 13, color: Colors.white54),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: const Color(0xFF2B2B2B),
              icon: Icon(
                plan.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: plan.pinned ? blue : Colors.white60,
              ),
              onSelected: (value) {
                if (value == 'pin') {
                  _togglePin(plan);
                } else if (value == 'edit') {
                  _openEdit(plan.id);
                } else if (value == 'delete') {
                  _deletePlan(plan);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pin',
                  child: Text(
                    plan.pinned ? 'Bỏ ghim' : 'Ghim lịch trình',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    'Sửa lịch trình',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Xóa lịch trình',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
