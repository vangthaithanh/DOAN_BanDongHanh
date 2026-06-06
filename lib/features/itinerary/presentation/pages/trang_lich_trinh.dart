import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../data/services/lich_trinh_nhom_service.dart';
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
  final LichTrinhNhomService _groupService = LichTrinhNhomService();

  late Future<List<_LichTrinhListItem>> _future;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _load();
    _service.kiemTraLichTrinhDangGhimBangGps();
    _groupService.kiemTraLichTrinhNhomDangGhim();
  }

  void _load() {
    _future = _loadAllPlans();
  }

  void _reload() {
    setState(_load);
  }

  void _markChangedAndReload() {
    setState(() {
      _hasChanges = true;
      _load();
    });
  }

  void _close() {
    Navigator.pop(context, _hasChanges);
  }

  Future<List<_LichTrinhListItem>> _loadAllPlans() async {
    final personalFuture = _service.layLichTrinhCuaToi();
    final groupFuture = _groupService.layDanhSachLichTrinhCuaToi();

    final personalPlans = await personalFuture;
    final groupPlans = await groupFuture;

    final items = <_LichTrinhListItem>[
      ...personalPlans.map(_LichTrinhListItem.personal),
      ...groupPlans.map(_LichTrinhListItem.group),
    ];

    items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.sortTime.compareTo(a.sortTime);
    });

    return items;
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
      _markChangedAndReload();
    }
  }

  Future<void> _openCreateGroup() async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.groupTripCreate,
    );

    if (!mounted) return;

    if (changed == true) {
      _markChangedAndReload();
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
      _hasChanges = true;
      Navigator.pop(context, true);
    }
  }

  Future<void> _openGroupDetail(int tripId) async {
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

  Future<void> _togglePin(LichTrinh plan) async {
    try {
      await _service.doiTrangThaiGhim(
        itineraryId: plan.id,
        pinned: !plan.pinned,
      );

      if (!mounted) return;

      _markChangedAndReload();

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

  Future<void> _togglePinGroup(TripGroup group) async {
    try {
      await _groupService.doiTrangThaiGhimNhom(
        tripId: group.id,
        pinned: !group.pinned,
      );

      if (!mounted) return;

      _markChangedAndReload();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            group.pinned
                ? 'Đã bỏ ghim lịch trình nhóm.'
                : 'Đã ghim lịch trình nhóm. GoMate sẽ nhắc giờ khi app đang mở.',
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

      if (!mounted) return;

      _hasChanges = true;
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
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _openCreateGroup,
                      icon: const Icon(Icons.groups_rounded, size: 18),
                      label: Text(
                        'Tạo nhóm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(size: 14, weight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _openCreate,
                      icon: const Icon(Icons.event_note_outlined, size: 18),
                      label: Text(
                        'Tạo cá nhân',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(size: 14, weight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: FutureBuilder<List<_LichTrinhListItem>>(
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
              'Lịch trình',
              textAlign: TextAlign.center,
              style: _text(size: 22, weight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _body(AsyncSnapshot<List<_LichTrinhListItem>> snapshot) {
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

  Widget _planTile(_LichTrinhListItem item) {
    if (item.isGroup) {
      final group = item.group!;
      final isOwner = group.ownerId == _groupService.currentUserId;

      return InkWell(
        onTap: () => _openGroupDetail(group.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 20, 18),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(size: 22, weight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _typeBadge('Nhóm'),
                        if (group.pinned) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.push_pin, color: blue, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group.dateText,
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
                      '${group.memberCount} thành viên • ${group.stopCount} điểm đến',
                      style: _text(size: 13, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF2B2B2B),
                icon: Icon(
                  group.pinned ? Icons.push_pin : Icons.more_horiz,
                  color: group.pinned ? blue : Colors.white60,
                ),
                onSelected: (value) {
                  if (value == 'pin') {
                    _togglePinGroup(group);
                  } else if (value == 'open') {
                    _openGroupDetail(group.id);
                  } else if (value == 'edit') {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.groupTripCreate,
                      arguments: {'tripId': group.id},
                    ).then((changed) {
                      if (mounted && changed == true) {
                        _markChangedAndReload();
                      }
                    });
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(
                      group.pinned ? 'Bỏ ghim' : 'Ghim lịch trình',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'open',
                    child: Text(
                      'Xem lịch trình',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  if (isOwner)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Sửa lịch trình',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final plan = item.personal!;

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

  Widget _typeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF183B59),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: _text(size: 10, weight: FontWeight.w800, color: blue),
      ),
    );
  }
}

class _LichTrinhListItem {
  final LichTrinh? personal;
  final TripGroup? group;

  const _LichTrinhListItem._({this.personal, this.group});

  factory _LichTrinhListItem.personal(LichTrinh plan) {
    return _LichTrinhListItem._(personal: plan);
  }

  factory _LichTrinhListItem.group(TripGroup group) {
    return _LichTrinhListItem._(group: group);
  }

  bool get isGroup => group != null;

  bool get pinned => personal?.pinned == true || group?.pinned == true;

  DateTime get sortTime {
    final personalTime =
        personal?.actualStartTime ?? personal?.startDate ?? personal?.endDate;
    if (personalTime != null) return personalTime;
    return group?.actualStartTime ??
        group?.createdAt ??
        group?.startDate ??
        DateTime(1970);
  }
}
