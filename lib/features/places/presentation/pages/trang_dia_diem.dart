import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../data/services/dia_diem_service.dart';
import '../../data/models/dia_diem_model.dart';
import '../widgets/place_common_widgets.dart';

class TrangDiaDiemPage extends StatefulWidget {
  const TrangDiaDiemPage({super.key});

  @override
  State<TrangDiaDiemPage> createState() => _TrangDiaDiemPageState();
}

class _TrangDiaDiemPageState extends State<TrangDiaDiemPage> {
  final TextEditingController _searchController = TextEditingController();
  final DiaDiemService _diaDiemService = DiaDiemService();

  List<DiaDiemModel> _tatCaDiaDiem = [];
  bool _dangTai = true;
  String? _loiTaiDuLieu;

  String _tuKhoa = '';
  final Set<String> _tinhThanhDaChon = {};
  final Set<String> _khoangCachDaChon = {};
  final Set<String> _tieuChiDaChon = {};
  final Set<String> _danhGiaDaChon = {};
  final Set<String> _soTienDaChon = {};

  static const List<String> _khoangCachOptions = [
    'Dưới 1 km',
    'Dưới 3 km',
    'Dưới 5 km',
    'Dưới 10 km',
    'Trên 10 km',
  ];

  static const List<String> _tieuChiOptions = [
    'Biển đảo',
    'Thiên nhiên',
    'Check-in',
    'Văn hóa',
    'Ẩm thực',
    'Mua sắm',
    'Đang hot',
  ];

  static const List<String> _danhGiaOptions = [
    'Từ 4,0 sao',
    'Từ 4,3 sao',
    'Từ 4,5 sao',
    'Từ 4,7 sao',
  ];

  static const List<String> _soTienOptions = [
    'Miễn phí',
    'Dưới 50.000đ',
    '50.000đ - 200.000đ',
    'Trên 200.000đ',
  ];

  List<String> get _tinhThanhOptions {
    final values = _tatCaDiaDiem.map((item) => item.tinhThanh).toSet().toList();
    values.sort();
    return values;
  }

  bool get _coBoLoc =>
      _tuKhoa.trim().isNotEmpty ||
      _tinhThanhDaChon.isNotEmpty ||
      _khoangCachDaChon.isNotEmpty ||
      _tieuChiDaChon.isNotEmpty ||
      _danhGiaDaChon.isNotEmpty ||
      _soTienDaChon.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _taiDiaDiem();
  }

  Future<void> _taiDiaDiem() async {
    setState(() {
      _dangTai = true;
      _loiTaiDuLieu = null;
    });

    try {
      final data = await _diaDiemService.layDanhSachDiaDiem();

      if (!mounted) return;

      setState(() {
        _tatCaDiaDiem = data;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loiTaiDuLieu = e.toString().replaceFirst('Exception: ', '');
        _dangTai = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_DiaDiemCoDiem> get _ketQuaHienThi {
    final List<_DiaDiemCoDiem> ketQua = [];

    for (final diaDiem in _tatCaDiaDiem) {
      if (diaDiem.trangThai != 'active') continue;
      if (!_khopBoLoc(diaDiem)) continue;

      final keywordScore = _tinhDiemTuKhoa(diaDiem, _tuKhoa);
      if (_tuKhoa.trim().isNotEmpty && keywordScore <= 0) continue;

      final ratingScore = diaDiem.diemTrungBinh * 2;
      final hotScore = diaDiem.tongLuotLuu >= 2000 ? 4 : 0;

      ketQua.add(
        _DiaDiemCoDiem(
          diaDiem: diaDiem,
          diemKhop: keywordScore + ratingScore + hotScore,
        ),
      );
    }

    ketQua.sort((a, b) {
      final compareScore = b.diemKhop.compareTo(a.diemKhop);
      if (compareScore != 0) return compareScore;

      final compareRating =
          b.diaDiem.diemTrungBinh.compareTo(a.diaDiem.diemTrungBinh);
      if (compareRating != 0) return compareRating;

      return b.diaDiem.tongLuotLuu.compareTo(a.diaDiem.tongLuotLuu);
    });

    return ketQua;
  }

  @override
  Widget build(BuildContext context) {
    final ketQua = _ketQuaHienThi;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.05).clamp(16.0, 28.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  20,
                ),
                children: [
                  _header(context),
                  const SizedBox(height: 18),
                  _searchAndFilter(),
                  const SizedBox(height: 12),
                  _filterChips(),
                  const SizedBox(height: 20),
                  _resultTitle(ketQua.length),
                  const SizedBox(height: 8),
                  if (_dangTai)
                    _loadingBox()
                  else if (_loiTaiDuLieu != null)
                    _errorBox()
                  else if (ketQua.isEmpty)
                    _emptyResultBox()
                  else
                    ...ketQua.map(
                      (item) => PlaceCard(
                        diaDiem: item.diaDiem,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.placeDetail,
                            arguments: item.diaDiem.maDiaDiem,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const AppBottomNav(activeTab: MainTab.map),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _moBanDoThanhPhoHoChiMinh,
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.map_outlined, color: Colors.white, size: 28),
          ),
        ),
        const Spacer(),
        RichText(
          text: const TextSpan(
            text: 'Go',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            children: [
              TextSpan(
                text: 'Mate',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _searchAndFilter() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: _moBangLocTatCa,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF3B3B3B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _tuKhoa = value;
                });
              },
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Tìm Kiếm',
                hintStyle: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _tuKhoa.trim().isEmpty
                    ? null
                    : InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _tuKhoa = '';
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(top: 9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _filterButton(
          title: 'Tỉnh thành',
          selectedValues: _tinhThanhDaChon,
          onTap: () => _moBangChonMotNhom(
            title: 'Tỉnh thành',
            options: _tinhThanhOptions,
            selectedValues: _tinhThanhDaChon,
          ),
          onClear: () => setState(_tinhThanhDaChon.clear),
        ),
        _filterButton(
          title: 'Khoảng cách',
          selectedValues: _khoangCachDaChon,
          onTap: () => _moBangChonMotNhom(
            title: 'Khoảng cách',
            options: _khoangCachOptions,
            selectedValues: _khoangCachDaChon,
          ),
          onClear: () => setState(_khoangCachDaChon.clear),
        ),
        _filterButton(
          title: 'Tiêu chí',
          selectedValues: _tieuChiDaChon,
          onTap: () => _moBangChonMotNhom(
            title: 'Tiêu chí',
            options: _tieuChiOptions,
            selectedValues: _tieuChiDaChon,
          ),
          onClear: () => setState(_tieuChiDaChon.clear),
        ),
        _filterButton(
          title: 'Đánh giá',
          selectedValues: _danhGiaDaChon,
          onTap: () => _moBangChonMotNhom(
            title: 'Đánh giá',
            options: _danhGiaOptions,
            selectedValues: _danhGiaDaChon,
          ),
          onClear: () => setState(_danhGiaDaChon.clear),
        ),
        _filterButton(
          title: 'Số tiền',
          selectedValues: _soTienDaChon,
          onTap: () => _moBangChonMotNhom(
            title: 'Số tiền',
            options: _soTienOptions,
            selectedValues: _soTienDaChon,
          ),
          onClear: () => setState(_soTienDaChon.clear),
        ),
      ],
    );
  }

  Widget _filterButton({
    required String title,
    required Set<String> selectedValues,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final isActive = selectedValues.isNotEmpty;
    final label = isActive ? '$title: ${_shortSelectedLabel(selectedValues)}' : title;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 8, isActive ? 8 : 16, 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryDark : const Color(0xFF3B3B3B),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 5),
              InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultTitle(int count) {
    return Text.rich(
      TextSpan(
        text: _coBoLoc ? 'Kết quả phù hợp ' : 'Đề xuất ',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        children: [
          TextSpan(
            text: _coBoLoc
                ? '($count địa điểm, sắp xếp theo độ khớp)'
                : '(theo tiêu chí gần định vị & đang hot)',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingBox() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đang tải địa điểm từ Supabase...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 40),
          const SizedBox(height: 10),
          const Text(
            'Không tải được dữ liệu địa điểm',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _loiTaiDuLieu ?? 'Lỗi không xác định',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          BluePillButton(text: 'Thử lại', onTap: _taiDiaDiem),
        ],
      ),
    );
  }

  Widget _emptyResultBox() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.travel_explore_rounded, color: Colors.white70, size: 40),
          const SizedBox(height: 10),
          const Text(
            'Không tìm thấy địa điểm phù hợp',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bạn thử xóa bớt bộ lọc hoặc đổi từ khóa tìm kiếm nha.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          BluePillButton(text: 'Xóa tất cả bộ lọc', onTap: _xoaTatCaBoLoc),
        ],
      ),
    );
  }

  void _xoaTatCaBoLoc() {
    _searchController.clear();
    setState(() {
      _tuKhoa = '';
      _tinhThanhDaChon.clear();
      _khoangCachDaChon.clear();
      _tieuChiDaChon.clear();
      _danhGiaDaChon.clear();
      _soTienDaChon.clear();
    });
  }

  Future<void> _moBangChonMotNhom({
    required String title,
    required List<String> options,
    required Set<String> selectedValues,
  }) async {
    final temp = Set<String>.from(selectedValues);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHeader(title),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                      ),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: options.map((option) {
                            return _sheetChoiceChip(
                              text: option,
                              selected: temp.contains(option),
                              onTap: () {
                                modalSetState(() {
                                  if (temp.contains(option)) {
                                    temp.remove(option);
                                  } else {
                                    temp.add(option);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              modalSetState(temp.clear);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text('Xóa'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedValues
                                  ..clear()
                                  ..addAll(temp);
                              });
                              Navigator.pop(sheetContext);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text('OK'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _moBangLocTatCa() async {
    final tempTinhThanh = Set<String>.from(_tinhThanhDaChon);
    final tempKhoangCach = Set<String>.from(_khoangCachDaChon);
    final tempTieuChi = Set<String>.from(_tieuChiDaChon);
    final tempDanhGia = Set<String>.from(_danhGiaDaChon);
    final tempSoTien = Set<String>.from(_soTienDaChon);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.78,
                minChildSize: 0.45,
                maxChildSize: 0.92,
                builder: (context, scrollController) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetHeader('Bộ lọc địa điểm'),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              _sheetSection(
                                title: 'Tỉnh thành',
                                options: _tinhThanhOptions,
                                selectedValues: tempTinhThanh,
                                modalSetState: modalSetState,
                              ),
                              _sheetSection(
                                title: 'Khoảng cách',
                                options: _khoangCachOptions,
                                selectedValues: tempKhoangCach,
                                modalSetState: modalSetState,
                              ),
                              _sheetSection(
                                title: 'Tiêu chí',
                                options: _tieuChiOptions,
                                selectedValues: tempTieuChi,
                                modalSetState: modalSetState,
                              ),
                              _sheetSection(
                                title: 'Đánh giá',
                                options: _danhGiaOptions,
                                selectedValues: tempDanhGia,
                                modalSetState: modalSetState,
                              ),
                              _sheetSection(
                                title: 'Số tiền',
                                options: _soTienOptions,
                                selectedValues: tempSoTien,
                                modalSetState: modalSetState,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  modalSetState(() {
                                    tempTinhThanh.clear();
                                    tempKhoangCach.clear();
                                    tempTieuChi.clear();
                                    tempDanhGia.clear();
                                    tempSoTien.clear();
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text('Xóa lọc'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _tinhThanhDaChon
                                      ..clear()
                                      ..addAll(tempTinhThanh);
                                    _khoangCachDaChon
                                      ..clear()
                                      ..addAll(tempKhoangCach);
                                    _tieuChiDaChon
                                      ..clear()
                                      ..addAll(tempTieuChi);
                                    _danhGiaDaChon
                                      ..clear()
                                      ..addAll(tempDanhGia);
                                    _soTienDaChon
                                      ..clear()
                                      ..addAll(tempSoTien);
                                  });
                                  Navigator.pop(sheetContext);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text('Lọc'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetHeader(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _sheetSection({
    required String title,
    required List<String> options,
    required Set<String> selectedValues,
    required StateSetter modalSetState,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              return _sheetChoiceChip(
                text: option,
                selected: selectedValues.contains(option),
                onTap: () {
                  modalSetState(() {
                    if (selectedValues.contains(option)) {
                      selectedValues.remove(option);
                    } else {
                      selectedValues.add(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sheetChoiceChip({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moBanDoThanhPhoHoChiMinh() {
    Navigator.pushNamed(
      context,
      AppRoutes.map,
      arguments: const {
        'lat': 10.776889,
        'lng': 106.700806,
        'ten': 'TP. Hồ Chí Minh',
        'originLat': 10.776889,
        'originLng': 106.700806,
      },
    );
  }

  String _shortSelectedLabel(Set<String> values) {
    if (values.isEmpty) return '';
    final first = values.first;
    if (values.length == 1) return first;
    return '$first +${values.length - 1}';
  }

  bool _khopBoLoc(DiaDiemModel diaDiem) {
    if (_tinhThanhDaChon.isNotEmpty &&
        !_tinhThanhDaChon.contains(diaDiem.tinhThanh)) {
      return false;
    }

    if (!_khopKhoangCach(diaDiem)) return false;
    if (!_khopTieuChi(diaDiem)) return false;
    if (!_khopDanhGia(diaDiem)) return false;
    if (!_khopSoTien(diaDiem)) return false;

    return true;
  }

  bool _khopKhoangCach(DiaDiemModel diaDiem) {
    if (_khoangCachDaChon.isEmpty) return true;

    final distanceKm = _layKhoangCachKm(diaDiem.khoangCach);
    if (distanceKm == null) return false;

    return _khoangCachDaChon.any((option) {
      switch (option) {
        case 'Dưới 1 km':
          return distanceKm <= 1;
        case 'Dưới 3 km':
          return distanceKm <= 3;
        case 'Dưới 5 km':
          return distanceKm <= 5;
        case 'Dưới 10 km':
          return distanceKm <= 10;
        case 'Trên 10 km':
          return distanceKm > 10;
      }
      return true;
    });
  }

  bool _khopTieuChi(DiaDiemModel diaDiem) {
    if (_tieuChiDaChon.isEmpty) return true;

    final text = _normalize(
      '${diaDiem.tenDiaDiem} ${diaDiem.tinhThanh} ${diaDiem.quanHuyen ?? ''} '
      '${diaDiem.diaChi ?? ''} ${diaDiem.tuKhoa ?? ''} ${diaDiem.moTa ?? ''}',
    );

    return _tieuChiDaChon.any((option) {
      final terms = _termsTheoTieuChi(option);
      return terms.any(text.contains);
    });
  }

  bool _khopDanhGia(DiaDiemModel diaDiem) {
    if (_danhGiaDaChon.isEmpty) return true;

    return _danhGiaDaChon.any((option) {
      final value = double.tryParse(
        option
            .replaceAll('Từ', '')
            .replaceAll('sao', '')
            .replaceAll(',', '.')
            .trim(),
      );

      if (value == null) return true;
      return diaDiem.diemTrungBinh >= value;
    });
  }

  bool _khopSoTien(DiaDiemModel diaDiem) {
    if (_soTienDaChon.isEmpty) return true;

    final price = diaDiem.mucGia ?? 0;

    return _soTienDaChon.any((option) {
      switch (option) {
        case 'Miễn phí':
          return price == 0;
        case 'Dưới 50.000đ':
          return price > 0 && price < 50000;
        case '50.000đ - 200.000đ':
          return price >= 50000 && price <= 200000;
        case 'Trên 200.000đ':
          return price > 200000;
      }
      return true;
    });
  }

  double? _layKhoangCachKm(String value) {
    final lower = value.toLowerCase().replaceAll(',', '.');
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower);
    if (match == null) return null;

    final number = double.tryParse(match.group(1) ?? '');
    if (number == null) return null;

    if (lower.contains('m') && !lower.contains('km')) {
      return number / 1000;
    }

    return number;
  }

  List<String> _termsTheoTieuChi(String option) {
    switch (option) {
      case 'Biển đảo':
        return ['bien', 'dao', 'bai tam'];
      case 'Thiên nhiên':
        return ['thien nhien', 'nui', 'rung', 'trekking', 'ngam canh'];
      case 'Check-in':
        return ['checkin', 'check in', 'song ao', 'chup anh', 'hot'];
      case 'Văn hóa':
        return ['van hoa', 'lich su', 'di tich', 'kien truc', 'co do'];
      case 'Ẩm thực':
        return ['am thuc', 'an uong', 'dac san', 'cho dem', 'food'];
      case 'Mua sắm':
        return ['mua sam', 'cho', 'mall', 'luu niem'];
      case 'Đang hot':
        return ['hot', 'trending', 'noi tieng'];
    }

    return [_normalize(option)];
  }

  double _tinhDiemTuKhoa(DiaDiemModel diaDiem, String keyword) {
    final q = _normalize(keyword);
    if (q.isEmpty) return 10;

    double score = 0;
    final name = _normalize(diaDiem.tenDiaDiem);
    final province = _normalize(diaDiem.tinhThanh);
    final district = _normalize(diaDiem.quanHuyen ?? '');
    final address = _normalize(diaDiem.diaChi ?? '');
    final keywords = _normalize(diaDiem.tuKhoa ?? '');
    final description = _normalize(diaDiem.moTa ?? '');

    if (name.contains(q)) score += 100;
    if (keywords.contains(q)) score += 80;
    if (province.contains(q) || district.contains(q) || address.contains(q)) {
      score += 65;
    }
    if (description.contains(q)) score += 35;

    final tokens = q.split(' ').where((item) => item.trim().isNotEmpty);
    for (final token in tokens) {
      if (name.contains(token)) score += 18;
      if (keywords.contains(token)) score += 14;
      if (province.contains(token) || district.contains(token)) score += 10;
      if (address.contains(token)) score += 8;
      if (description.contains(token)) score += 5;
    }

    return score;
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

class _DiaDiemCoDiem {
  final DiaDiemModel diaDiem;
  final double diemKhop;

  const _DiaDiemCoDiem({required this.diaDiem, required this.diemKhop});
}
