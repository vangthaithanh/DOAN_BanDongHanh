import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/dia_diem_model.dart';
import '../../data/services/dia_diem_service.dart';
import '../widgets/place_common_widgets.dart';

class TrangChiTietDiaDiemPage extends StatefulWidget {
  const TrangChiTietDiaDiemPage({super.key});

  @override
  State<TrangChiTietDiaDiemPage> createState() => _TrangChiTietDiaDiemPageState();
}

class _TrangChiTietDiaDiemPageState extends State<TrangChiTietDiaDiemPage> {
  final DiaDiemService _service = DiaDiemService();

  DiaDiemModel? _diaDiem;
  List<DiaDiemModel> _diaDiemLienQuan = [];
  List<DanhGiaDiaDiemModel> _danhGiaGanDay = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_diaDiem == null && _dangTai) {
      final id = ModalRoute.of(context)?.settings.arguments as int?;
      _taiDuLieu(id);
    }
  }

  Future<void> _taiDuLieu(int? id) async {
    if (id == null) {
      setState(() {
        _dangTai = false;
        _loi = 'Không nhận được mã địa điểm.';
      });
      return;
    }

    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      final diaDiem = await _service.layDiaDiemTheoId(id);

      if (diaDiem == null) {
        if (!mounted) return;
        setState(() {
          _dangTai = false;
          _loi = 'Không tìm thấy địa điểm này.';
        });
        return;
      }

      final related = await _service.layDiaDiemLienQuan(diaDiem);
      final reviews = await _service.layDanhGiaTheoDiaDiem(id, limit: 3);

      if (!mounted) return;
      setState(() {
        _diaDiem = diaDiem;
        _diaDiemLienQuan = related;
        _danhGiaGanDay = reviews;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dangTai = false;
        _loi = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (width * 0.05).clamp(16.0, 24.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _dangTai
            ? const Center(child: CircularProgressIndicator())
            : _loi != null
                ? _errorView()
                : RefreshIndicator(
                    onRefresh: () => _taiDuLieu(_diaDiem!.maDiaDiem),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        22,
                      ),
                      children: [
                        _header(_diaDiem!),
                        const SizedBox(height: 16),
                        _locationBox(_diaDiem!),
                        const SizedBox(height: 18),
                        _imageList(_diaDiem!.hinhAnh),
                        const SizedBox(height: 18),
                        _descriptionBox(_diaDiem!),
                        const SizedBox(height: 18),
                        _ratingBox(_diaDiem!),
                        const SizedBox(height: 12),
                        _reviews(_diaDiem!),
                        const SizedBox(height: 22),
                        _suggestionTitle(),
                        const SizedBox(height: 8),
                        if (_diaDiemLienQuan.isEmpty)
                          const Text(
                            'Chưa có địa điểm liên quan.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          ..._diaDiemLienQuan.map((item) => PlaceCard(diaDiem: item)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 42),
            const SizedBox(height: 12),
            Text(
              _loi ?? 'Lỗi không xác định',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            BluePillButton(text: 'Quay lại', onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _header(DiaDiemModel diaDiem) {
    return Row(
      children: [
        const BackCircleButton(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            diaDiem.tenDiaDiem,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _moBanDo(diaDiem),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF3A3A3A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map_outlined, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _locationBox(DiaDiemModel diaDiem) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 350;

        final info = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${diaDiem.khoangCach} • ${diaDiem.thoiGianUocTinh}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    diaDiem.diaChiHienThi,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (diaDiem.gioMoCua != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Giờ mở cửa: ${diaDiem.gioMoCua}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isSmall
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BluePillButton(
                        text: 'Xem vị trí',
                        onTap: () => _moBanDo(diaDiem),
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 10),
                    BluePillButton(
                      text: 'Xem vị trí',
                      onTap: () => _moBanDo(diaDiem),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _imageList(List<String> images) {
    final width = MediaQuery.sizeOf(context).width;
    final itemWidth = (width * 0.34).clamp(112.0, 142.0).toDouble();
    final itemHeight = (itemWidth * 0.92).clamp(106.0, 128.0).toDouble();

    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          return PlaceImage(
            path: images[index],
            width: itemWidth,
            height: itemHeight,
            borderRadius: BorderRadius.circular(10),
          );
        },
      ),
    );
  }

  Widget _descriptionBox(DiaDiemModel diaDiem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin địa điểm',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          diaDiem.moTaHienThi,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _smallInfoChip(Icons.paid_outlined, diaDiem.giaTrungBinh),
            _smallInfoChip(Icons.bookmark_border_rounded, '${diaDiem.soLuotThich} lượt lưu'),
            _smallInfoChip(Icons.place_outlined, diaDiem.tinhThanh),
          ],
        ),
      ],
    );
  }

  Widget _smallInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2F2F2F),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBox(DiaDiemModel diaDiem) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingText(rating: diaDiem.diemTrungBinh, iconSize: 21, fontSize: 15),
                const SizedBox(height: 6),
                Text(
                  '${diaDiem.tongDanhGia} lượt đánh giá',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${diaDiem.soLuotThich} lượt lưu địa điểm',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          BluePillButton(
            text: 'Đánh giá',
            onTap: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.placeReview,
                arguments: diaDiem.maDiaDiem,
              );
              _taiDuLieu(diaDiem.maDiaDiem);
            },
          ),
        ],
      ),
    );
  }

  Widget _reviews(DiaDiemModel diaDiem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Đánh giá gần đây ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(
                      text: '(lấy từ Supabase)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  AppRoutes.placeReview,
                  arguments: diaDiem.maDiaDiem,
                );
                _taiDuLieu(diaDiem.maDiaDiem);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Viết mới',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_danhGiaGanDay.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Chưa có đánh giá nào. Bạn có thể là người đầu tiên đánh giá địa điểm này.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          )
        else
          ..._danhGiaGanDay.map((item) => ReviewTile(review: item)),
      ],
    );
  }

  Widget _suggestionTitle() {
    return const Text.rich(
      TextSpan(
        text: 'Đề xuất ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        children: [
          TextSpan(
            text: '(địa điểm liên quan từ Supabase)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _moBanDo(DiaDiemModel diaDiem) {
    Navigator.pushNamed(
      context,
      AppRoutes.map,
      arguments: {
        'lat': diaDiem.viDo,
        'lng': diaDiem.kinhDo,
        'ten': diaDiem.tenDiaDiem,
        'originLat': 10.776889,
        'originLng': 106.700806,
      },
    );
  }
}
