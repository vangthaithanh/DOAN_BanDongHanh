import 'package:flutter/material.dart';

import '../../data/services/lich_trinh_service.dart';
import '../../../../app/routes/app_routes.dart';

class TrangThemSuaLichTrinhPage extends StatefulWidget {
  final int? itineraryId;
  final int? initialPlaceId;

  const TrangThemSuaLichTrinhPage({
    super.key,
    this.itineraryId,
    this.initialPlaceId,
  });

  @override
  State<TrangThemSuaLichTrinhPage> createState() =>
      _TrangThemSuaLichTrinhPageState();
}

class _TrangThemSuaLichTrinhPageState extends State<TrangThemSuaLichTrinhPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color lineGrey = Color(0xFF313131);

  final LichTrinhService _service = LichTrinhService();

  final TextEditingController _tenController = TextEditingController();
  final TextEditingController _ghiChuController = TextEditingController();
  final TextEditingController _timKiemDiaDiemController =
  TextEditingController();

  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;
  bool _ghim = false;
  bool _dangTai = true;
  bool _dangLuu = false;
  int _ngayDangChonIndex = 0;

  List<DiaDiemLichTrinh> _diaDiem = [];
  final List<_DraftLichTrinhItem> _items = [];

  bool get _isEdit => widget.itineraryId != null;

  @override
  void initState() {
    super.initState();
    _khoiTao();
  }

  @override
  void dispose() {
    _tenController.dispose();
    _ghiChuController.dispose();
    _timKiemDiaDiemController.dispose();
    super.dispose();
  }

  Future<void> _khoiTao() async {
    try {
      final places = await _service.layDiaDiemDeChon();

      LichTrinh? plan;

      if (_isEdit) {
        plan = await _service.layChiTietLichTrinh(widget.itineraryId!);
      }

      if (!mounted) return;

      _diaDiem = places;

      if (plan != null) {
        _tenController.text = plan.name;
        _ghiChuController.text = plan.description;
        _ngayBatDau = plan.startDate;
        _ngayKetThuc = plan.endDate;
        _ghim = plan.pinned;

        _items
          ..clear()
          ..addAll(
            plan.items.map((item) {
              final place = item.place ??
                  _diaDiem.firstWhere(
                        (p) => p.id == item.placeId,
                    orElse: () => DiaDiemLichTrinh(
                      id: item.placeId,
                      ten: item.tenDiaDiem,
                      tinhThanh: '',
                      quanHuyen: null,
                      diaChi: null,
                      viDo: 0,
                      kinhDo: 0,
                      diemTrungBinh: 0,
                      tongDanhGia: 0,
                    ),
                  );

              return _DraftLichTrinhItem(
                place: place,
                plannedTime: item.plannedTime ?? DateTime.now(),
                note: item.note,
              );
            }),
          );
      } else {
        _tenController.text = 'Plan 1';
        final now = DateTime.now();
        _ngayBatDau = DateTime(now.year, now.month, now.day);
        _ngayKetThuc = _ngayBatDau;

        if (widget.initialPlaceId != null) {
          final initial = _diaDiem.where((p) => p.id == widget.initialPlaceId);
          if (initial.isNotEmpty) {
            _items.add(
              _DraftLichTrinhItem(
                place: initial.first,
                plannedTime: DateTime(
                  now.year,
                  now.month,
                  now.day,
                  now.hour + 1,
                  0,
                ),
              ),
            );
          }
        }
      }

      setState(() {
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _dangTai = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
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

  Future<void> _chonNgay({required bool start}) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: start
          ? (_ngayBatDau ?? now)
          : (_ngayKetThuc ?? _ngayBatDau ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (start) {
        _ngayBatDau = picked;

        if (_ngayKetThuc != null && _ngayKetThuc!.isBefore(picked)) {
          _ngayKetThuc = picked;
        }
      } else {
        _ngayKetThuc = picked;

        if (_ngayBatDau != null && _ngayBatDau!.isAfter(picked)) {
          _ngayBatDau = picked;
        }
      }

      _canBangNgayDangChon();
    });
  }

  Future<void> _chonThoiGianChoItem(int index) async {
    final item = _items[index];

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: item.plannedTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(item.plannedTime),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _items[index] = item.copyWith(
        plannedTime: DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        ),
      );
    });
  }

  Future<void> _moChonDiaDiem() async {
    if (_ngayBatDau == null || _ngayKetThuc == null || _ngayDangChon == null) {
      _showMessage('Bạn cần chọn ngày đi và ngày về trước.');
      return;
    }
    _timKiemDiaDiemController.clear();


    final selected = await showModalBottomSheet<DiaDiemLichTrinh>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var places = List<DiaDiemLichTrinh>.from(_diaDiem);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void filter(String keyword) {
              final lower = keyword.trim().toLowerCase();

              setSheetState(() {
                places = _diaDiem.where((place) {
                  final text =
                  '${place.ten} ${place.tinhThanh} ${place.quanHuyen ?? ''} ${place.diaChi ?? ''}'
                      .toLowerCase();
                  return text.contains(lower);
                }).toList();
              });
            }

            return Container(
              height: MediaQuery.sizeOf(context).height * 0.86,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF151515),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _timKiemDiaDiemController,
                    onChanged: filter,
                    style: _text(),
                    decoration: InputDecoration(
                      hintText: 'Tìm địa điểm',
                      hintStyle: _text(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white60),
                      filled: true,
                      fillColor: darkGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: places.isEmpty
                        ? Center(
                      child: Text(
                        'Không tìm thấy địa điểm',
                        style: _text(color: Colors.white60),
                      ),
                    )
                        : ListView.separated(
                      itemCount: places.length,
                      separatorBuilder: (_, __) =>
                      const Divider(color: lineGrey, height: 1),
                      itemBuilder: (context, index) {
                        final place = places[index];

                        return ListTile(
                          onTap: () => Navigator.pop(context, place),
                          contentPadding: EdgeInsets.zero,
                          leading: _placeThumb(place.imageUrl, size: 50),
                          title: Text(
                            place.ten,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(weight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            [
                              place.quanHuyen,
                              place.tinhThanh,
                            ].whereType<String>().join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _text(
                              size: 12,
                              color: Colors.white60,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.placeDetail,
                                arguments: place.id,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected == null) return;

    final plannedTime = await _chonGioSauKhiChonDiaDiem(selected);

    if (plannedTime == null) {
      _showMessage('Bạn cần chọn thời gian để thêm địa điểm vào lịch trình.');
      return;
    }

    setState(() {
      _items.add(
        _DraftLichTrinhItem(
          place: selected,
          plannedTime: plannedTime,
        ),
      );

      _items.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));
    });
  }

  Future<DateTime?> _chonGioSauKhiChonDiaDiem(
      DiaDiemLichTrinh place,
      ) async {
    final selectedDate = _ngayDangChon;

    if (selectedDate == null) {
      _showMessage('Bạn cần chọn ngày trong lịch trình trước.');
      return null;
    }

    final now = DateTime.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: now.hour + 1 > 23 ? 23 : now.hour + 1,
        minute: 0,
      ),
      helpText: 'Chọn giờ đi ${place.ten}',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedTime == null) return null;

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _luu() async {
    if (_dangLuu) return;

    setState(() {
      _dangLuu = true;
    });

    try {
      final draftItems = _items
          .map(
            (item) => LichTrinhDraftItem(
          placeId: item.place.id,
          plannedTime: item.plannedTime,
          note: item.note,
        ),
      )
          .toList();

      if (_isEdit) {
        await _service.capNhatLichTrinh(
          itineraryId: widget.itineraryId!,
          name: _tenController.text,
          description: _ghiChuController.text,
          startDate: _ngayBatDau,
          endDate: _ngayKetThuc,
          pinned: _ghim,
          items: draftItems,
        );
      } else {
        await _service.taoLichTrinh(
          name: _tenController.text,
          description: _ghiChuController.text,
          startDate: _ngayBatDau,
          endDate: _ngayKetThuc,
          pinned: _ghim,
          items: draftItems,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _dangLuu = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _dateText(DateTime? date, String fallback) {
    if (date == null) return fallback;
    return '${date.day}/${date.month}/${date.year}';
  }

  String _timeText(DateTime date) {
    final gio = date.hour.toString().padLeft(2, '0');
    final phut = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}, $gio:$phut';
  }
  int get _soNgayLichTrinh {
    if (_ngayBatDau == null || _ngayKetThuc == null) return 0;

    final start = DateTime(
      _ngayBatDau!.year,
      _ngayBatDau!.month,
      _ngayBatDau!.day,
    );

    final end = DateTime(
      _ngayKetThuc!.year,
      _ngayKetThuc!.month,
      _ngayKetThuc!.day,
    );

    final count = end.difference(start).inDays + 1;

    if (count < 1) return 1;
    return count;
  }

  DateTime? get _ngayDangChon {
    if (_ngayBatDau == null) return null;

    return DateTime(
      _ngayBatDau!.year,
      _ngayBatDau!.month,
      _ngayBatDau!.day,
    ).add(Duration(days: _ngayDangChonIndex));
  }

  String _thuText(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      default:
        return 'CN';
    }
  }

  String _ngayChipText(int index) {
    final start = _ngayBatDau;

    if (start == null) {
      return 'Ngày ${index + 1}';
    }

    final date = DateTime(start.year, start.month, start.day).add(
      Duration(days: index),
    );

    return 'Ngày ${index + 1}';
  }

  String _ngayDangChonText() {
    final date = _ngayDangChon;

    if (date == null) return 'Chưa chọn ngày đi';

    return '${_thuText(date)} - ${date.day}/${date.month}';
  }

  bool _cungNgay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<_DraftLichTrinhItem> get _itemsTrongNgayDangChon {
    final selectedDate = _ngayDangChon;

    if (selectedDate == null) return [];

    final result = _items.where((item) {
      return _cungNgay(item.plannedTime, selectedDate);
    }).toList();

    result.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));

    return result;
  }

  void _canBangNgayDangChon() {
    final count = _soNgayLichTrinh;

    if (count <= 0) {
      _ngayDangChonIndex = 0;
      return;
    }

    if (_ngayDangChonIndex >= count) {
      _ngayDangChonIndex = count - 1;
    }

    if (_ngayDangChonIndex < 0) {
      _ngayDangChonIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dangTai) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 20),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _dangLuu ? null : _luu,
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                disabledBackgroundColor: blue.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _dangLuu
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                _isEdit ? 'Lưu lịch trình' : 'Tạo lịch trình',
                style: _text(size: 16, weight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
          children: [
            _topBar(),
            const SizedBox(height: 16),
            _inputTen(),
            const SizedBox(height: 12),
            _ghiChuBox(),
            const SizedBox(height: 20),
            _ngayBox(),
            const SizedBox(height: 18),
            _chonNgayNhanh(),
            const SizedBox(height: 20),
            _chonThongTinBox(),
            const SizedBox(height: 22),
            _timeline(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
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
            _isEdit ? 'Sửa lịch trình' : 'Thêm lịch trình',
            textAlign: TextAlign.center,
            style: _text(size: 22, weight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _inputTen() {
    return TextField(
      controller: _tenController,
      style: _text(size: 15, weight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: 'Nhập tên lịch trình',
        hintStyle: _text(color: Colors.white60),
        filled: true,
        fillColor: darkGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _ghiChuBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lineGrey),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ghiChuController,
              maxLines: 2,
              style: _text(size: 13),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Ghi chú\nPlan này để làm gì',
                hintStyle: _text(size: 12, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              setState(() {
                _ghim = !_ghim;
              });
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: _ghim ? blue : darkGrey,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _ghim ? 'Đã ghim' : 'Ghim',
                style: _text(size: 12, weight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ngayBox() {
    return Row(
      children: [
        const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 24),
        const SizedBox(width: 18),
        Expanded(
          child: _smallPill(
            text: _dateText(_ngayBatDau, 'Từ ngày'),
            onTap: () => _chonNgay(start: true),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _smallPill(
            text: _dateText(_ngayKetThuc, 'Đến ngày'),
            onTap: () => _chonNgay(start: false),
          ),
        ),
      ],
    );
  }

  Widget _chonNgayNhanh() {
    final dayCount = _soNgayLichTrinh;

    if (dayCount <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Chọn ngày đi và ngày về để tạo các ngày trong lịch trình',
          style: _text(size: 12, color: Colors.white54),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dayCount,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final active = index == _ngayDangChonIndex;

              return InkWell(
                onTap: () {
                  setState(() {
                    _ngayDangChonIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 102,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? blue : darkGrey,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _ngayChipText(index),
                    style: _text(
                      size: 13,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đang thêm cho ${_ngayDangChonText()}',
          style: _text(size: 12, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _chonThongTinBox() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: lineGrey),
        borderRadius: BorderRadius.circular(18),
      ),
      child: _optionRow(
        icon: Icons.add_location_alt_outlined,
        text: 'Chọn địa điểm',
        onTap: _moChonDiaDiem,
      ),
    );
  }

  Widget _timeline() {
    final visibleItems = _itemsTrongNgayDangChon;

    if (_ngayDangChon == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          'Hãy chọn ngày đi và ngày về trước.',
          textAlign: TextAlign.center,
          style: _text(color: Colors.white60),
        ),
      );
    }

    if (visibleItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          'Chưa có địa điểm cho ${_ngayDangChonText()}.',
          textAlign: TextAlign.center,
          style: _text(color: Colors.white60),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          for (final item in visibleItems)
            _timelineItem(
              item: item,
              realIndex: _items.indexOf(item),
            ),
        ],
      ),
    );
  }

  Widget _placeThumb(String? imageUrl, {double size = 56}) {
    final url = imageUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF2B2B2B),
        child: url.isEmpty
            ? const Icon(
          Icons.image_outlined,
          color: Colors.white38,
        )
            : Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.image_outlined,
              color: Colors.white38,
            );
          },
        ),
      ),
    );
  }

  Widget _timelineItem({
    required int realIndex,
    required _DraftLichTrinhItem item,
  }) {
    final gio = item.plannedTime.hour.toString().padLeft(2, '0');
    final phut = item.plannedTime.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232323)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '$gio:$phut',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _text(
                size: 11.5,
                weight: FontWeight.w800,
                color: Colors.white60,
              ),
            ),
          ),

          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.white54,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 10),

          _placeThumb(item.place.imageUrl, size: 52),

          const SizedBox(width: 10),

          Expanded(
            child: InkWell(
              onTap: () => _chonThoiGianChoItem(realIndex),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.place.ten,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      size: 14.5,
                      weight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.place.tinhThanh.trim().isEmpty
                        ? 'Tỉnh thành'
                        : item.place.tinhThanh,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          InkWell(
            onTap: () {
              setState(() {
                _items.removeAt(realIndex);
              });
            },
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.close,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionRow({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: _text(size: 14, weight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _smallPill({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: darkGrey,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _text(size: 13, weight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DraftLichTrinhItem {
  final DiaDiemLichTrinh place;
  final DateTime plannedTime;
  final String note;

  const _DraftLichTrinhItem({
    required this.place,
    required this.plannedTime,
    this.note = '',
  });

  _DraftLichTrinhItem copyWith({
    DiaDiemLichTrinh? place,
    DateTime? plannedTime,
    String? note,
  }) {
    return _DraftLichTrinhItem(
      place: place ?? this.place,
      plannedTime: plannedTime ?? this.plannedTime,
      note: note ?? this.note,
    );
  }
}