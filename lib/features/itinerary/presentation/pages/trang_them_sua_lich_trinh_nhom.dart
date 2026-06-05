import 'package:flutter/material.dart';

import '../../data/services/lich_trinh_nhom_service.dart';
import '../../data/services/lich_trinh_service.dart';

class TrangThemSuaLichTrinhNhomPage extends StatefulWidget {
  final int? tripId;

  const TrangThemSuaLichTrinhNhomPage({super.key, this.tripId});

  @override
  State<TrangThemSuaLichTrinhNhomPage> createState() =>
      _TrangThemSuaLichTrinhNhomPageState();
}

class _TrangThemSuaLichTrinhNhomPageState
    extends State<TrangThemSuaLichTrinhNhomPage> {
  static const Color blue = Color(0xFF4AA8FF);
  static const Color darkGrey = Color(0xFF1D1D1D);
  static const Color fieldGrey = Color(0xFF242424);

  final LichTrinhNhomService _service = LichTrinhNhomService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  DateTime? _startDate;
  DateTime? _endDate;
  List<TripGroupFriend> _friends = [];
  List<DiaDiemLichTrinh> _places = [];
  final Set<String> _selectedFriendIds = {};
  final List<_DraftGroupStop> _stops = [];

  bool get _isEdit => widget.tripId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final friendsFuture = _service.layDanhSachBanBe();
      final placesFuture = _service.layDiaDiemDeChon();

      TripGroupDetail? detail;
      if (_isEdit) {
        detail = await _service.layChiTietLichTrinhNhom(widget.tripId!);
      }

      final friends = await friendsFuture;
      final places = await placesFuture;

      if (detail != null) {
        _titleController.text = detail.group.title;
        _descriptionController.text = detail.group.description;
        _startDate = detail.group.startDate;
        _endDate = detail.group.endDate;

        final currentUserId = _service.currentUserId;
        _selectedFriendIds
          ..clear()
          ..addAll(
            detail.members
                .where(
                  (item) =>
                      item.userId != currentUserId && item.role != 'owner',
                )
                .map((item) => item.userId),
          );

        _stops
          ..clear()
          ..addAll(
            detail.stops.map(
              (stop) => _DraftGroupStop(
                place: _placeFromStop(stop, places),
                arriveAt: stop.arriveAt,
                note: stop.note,
              ),
            ),
          );
      }

      if (!mounted) return;

      setState(() {
        _friends = friends;
        _places = places;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showError(e);
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

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: _text(color: Colors.white60),
      hintStyle: _text(color: Colors.white30),
      filled: true,
      fillColor: fieldGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: blue, width: 1.2),
      ),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: blue,
              surface: Color(0xFF202020),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickStopTime(int index) async {
    final stop = _stops[index];
    final date = await showDatePicker(
      context: context,
      initialDate: stop.arriveAt,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: blue,
              surface: Color(0xFF202020),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(stop.arriveAt),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: blue),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    final arriveAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _stops[index] = stop.copyWith(arriveAt: arriveAt);
    });
  }

  Future<void> _editStopNote(int index) async {
    final stop = _stops[index];
    final controller = TextEditingController(text: stop.note);

    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF202020),
          title: Text(
            'Ghi chú điểm đến',
            style: _text(size: 18, weight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: _text(),
            decoration: _decoration(
              'Ghi chú',
              hint: 'Ví dụ: tập trung ở cổng chính',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (note == null) return;

    setState(() {
      _stops[index] = stop.copyWith(note: note);
    });
  }

  Future<void> _showPlacePicker() async {
    final controller = TextEditingController();
    var keyword = '';

    final selected = await showModalBottomSheet<DiaDiemLichTrinh>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final clean = keyword.trim().toLowerCase();
            final places = clean.isEmpty
                ? _places
                : _places.where((place) {
                    return [
                      place.ten,
                      place.diaChi,
                      place.tinhThanh,
                      place.quanHuyen,
                    ].any(
                      (value) => (value ?? '').toLowerCase().contains(clean),
                    );
                  }).toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: TextField(
                        controller: controller,
                        style: _text(),
                        decoration: _decoration(
                          'Tìm địa điểm',
                          hint: 'Nhập tên, địa chỉ, tỉnh thành',
                        ),
                        onChanged: (value) {
                          setSheetState(() => keyword = value);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: places.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Color(0xFF282828), height: 1),
                        itemBuilder: (context, index) {
                          final place = places[index];
                          final selectedAlready = _stops.any(
                            (item) => item.place.id == place.id,
                          );

                          return ListTile(
                            enabled: !selectedAlready,
                            title: Text(
                              place.ten,
                              style: _text(
                                weight: FontWeight.w800,
                                color: selectedAlready
                                    ? Colors.white38
                                    : Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              place.diaChi ?? place.tinhThanh,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _text(color: Colors.white54),
                            ),
                            trailing: selectedAlready
                                ? const Icon(Icons.check, color: blue)
                                : const Icon(
                                    Icons.add_location_alt_outlined,
                                    color: Colors.white54,
                                  ),
                            onTap: selectedAlready
                                ? null
                                : () => Navigator.pop(context, place),
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
      },
    );

    controller.dispose();

    if (selected == null) return;

    final baseDate = _startDate ?? DateTime.now();
    final arriveAt = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
    ).add(Duration(hours: _stops.length + 1));

    setState(() {
      _stops.add(_DraftGroupStop(place: selected, arriveAt: arriveAt));
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final draftStops = _stops
          .map(
            (item) => TripGroupDraftStop(
              place: item.place,
              arriveAt: item.arriveAt,
              note: item.note,
            ),
          )
          .toList();

      if (_isEdit) {
        await _service.capNhatLichTrinhNhom(
          tripId: widget.tripId!,
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          memberIds: _selectedFriendIds.toList(),
          stops: draftStops,
        );
      } else {
        await _service.taoLichTrinhNhom(
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          memberIds: _selectedFriendIds.toList(),
          stops: draftStops,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEdit ? 'Sửa lịch trình nhóm' : 'Tạo lịch trình nhóm',
          style: _text(size: 19, weight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading || _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                disabledBackgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                _saving ? 'Đang lưu...' : 'Lưu lịch trình nhóm',
                style: _text(size: 16, weight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Thông tin'),
                  TextField(
                    controller: _titleController,
                    style: _text(),
                    decoration: _decoration('Tên lịch trình'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: _text(),
                    decoration: _decoration(
                      'Mô tả',
                      hint: 'Ghi chú chung cho nhóm',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _dateTile(
                          label: 'Ngày bắt đầu',
                          value: _formatDate(_startDate),
                          onTap: () => _pickDate(start: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateTile(
                          label: 'Ngày kết thúc',
                          value: _formatDate(_endDate),
                          onTap: () => _pickDate(start: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _sectionTitle('Bạn bè'),
                  _friendsSection(),
                  const SizedBox(height: 26),
                  _sectionTitle('Điểm đến'),
                  _stopsSection(),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: _text(size: 18, weight: FontWeight.w800)),
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: fieldGrey,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _text(size: 12, color: Colors.white54)),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _text(weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _friendsSection() {
    if (_friends.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkGrey,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Chưa có bạn bè theo dõi hai chiều để thêm vào lịch trình.',
          style: _text(color: Colors.white60),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: darkGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _friends.map((friend) {
          final selected = _selectedFriendIds.contains(friend.id);

          return CheckboxListTile(
            value: selected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedFriendIds.add(friend.id);
                } else {
                  _selectedFriendIds.remove(friend.id);
                }
              });
            },
            activeColor: blue,
            checkColor: Colors.white,
            controlAffinity: ListTileControlAffinity.trailing,
            title: Row(
              children: [
                _avatar(friend.avatarUrl, friend.name),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _stopsSection() {
    return Column(
      children: [
        if (_stops.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: darkGrey,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Chưa có điểm đến. Thêm địa điểm và đặt giờ có mặt cho nhóm.',
              style: _text(color: Colors.white60),
            ),
          )
        else
          ...List.generate(_stops.length, _stopCard),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _showPlacePicker,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text('Thêm địa điểm', style: _text(weight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stopCard(int index) {
    final stop = _stops[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF183B59),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: _text(weight: FontWeight.w800, color: blue),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.place.ten,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(size: 16, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stop.place.diaChi ?? stop.place.tinhThanh,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _text(size: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _stops.removeAt(index)),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickStopTime(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: fieldGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDateTime(stop.arriveAt),
                      style: _text(weight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => _editStopNote(index),
                child: Text(
                  stop.note.trim().isEmpty ? 'Ghi chú' : 'Sửa ghi chú',
                ),
              ),
            ],
          ),
          if (stop.note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(stop.note, style: _text(color: Colors.white60)),
          ],
        ],
      ),
    );
  }

  Widget _avatar(String? url, String name) {
    final cleanUrl = url?.trim() ?? '';

    return CircleAvatar(
      radius: 18,
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

  DiaDiemLichTrinh _placeFromStop(
    TripStop stop,
    List<DiaDiemLichTrinh> places,
  ) {
    for (final place in places) {
      if (place.id == stop.placeId) return place;
    }

    return DiaDiemLichTrinh(
      id: stop.placeId ?? 0,
      ten: stop.title,
      tinhThanh: '',
      quanHuyen: null,
      diaChi: stop.address,
      viDo: stop.latitude,
      kinhDo: stop.longitude,
      diemTrungBinh: 0,
      tongDanhGia: 0,
      imageUrl: null,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chọn ngày';
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }
}

class _DraftGroupStop {
  final DiaDiemLichTrinh place;
  final DateTime arriveAt;
  final String note;

  const _DraftGroupStop({
    required this.place,
    required this.arriveAt,
    this.note = '',
  });

  _DraftGroupStop copyWith({
    DiaDiemLichTrinh? place,
    DateTime? arriveAt,
    String? note,
  }) {
    return _DraftGroupStop(
      place: place ?? this.place,
      arriveAt: arriveAt ?? this.arriveAt,
      note: note ?? this.note,
    );
  }
}
