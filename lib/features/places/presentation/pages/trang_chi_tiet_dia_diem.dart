import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/mock/mock_dia_diem.dart';
import '../../data/models/dia_diem_model.dart';
import '../widgets/place_common_widgets.dart';

class TrangChiTietDiaDiemPage extends StatelessWidget {
  const TrangChiTietDiaDiemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as int?;
    final diaDiem = timDiaDiemTheoId(id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          children: [
            _header(context, diaDiem),
            const SizedBox(height: 16),
            _locationBox(context, diaDiem),
            const SizedBox(height: 24),
            _imageList(diaDiem.hinhAnh, height: 118),
            const SizedBox(height: 20),
            Text(
              diaDiem.moTaHienThi,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 70),
            _ratingBox(context, diaDiem),
            const SizedBox(height: 10),
            _reviews(diaDiem),
            const SizedBox(height: 20),
            const Text.rich(
              TextSpan(
                text: 'Đề xuất ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text:
                        '(Các địa điểm liên quan nhất, gần xung quanh cùng bộ lọc)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...mockDiaDiems
                .where((item) => item.maDiaDiem != diaDiem.maDiaDiem)
                .map((item) => PlaceCard(diaDiem: item)),
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  'Xem thêm',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, DiaDiemModel diaDiem) {
    return Row(
      children: [
        const BackCircleButton(),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            diaDiem.tenDiaDiem,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.map,
              arguments: {
                'lat': diaDiem.viDo,
                'lng': diaDiem.kinhDo,
                'ten': diaDiem.tenDiaDiem,
              },
            );
          },
          icon: const Icon(Icons.map_outlined, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _locationBox(BuildContext context, DiaDiemModel diaDiem) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diaDiem.khoangCach,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diaDiem.thoiGianUocTinh,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diaDiem.diaChiHienThi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          BluePillButton(
            text: 'Xem vị trí',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.map,
                arguments: {
                  'lat': diaDiem.viDo,
                  'lng': diaDiem.kinhDo,
                  'ten': diaDiem.tenDiaDiem,
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _imageList(List<String> images, {required double height}) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 3),
        itemBuilder: (context, index) {
          return PlaceImage(
            path: images[index],
            width: 126,
            height: height,
            borderRadius: BorderRadius.circular(8),
          );
        },
      ),
    );
  }

  Widget _ratingBox(BuildContext context, DiaDiemModel diaDiem) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                RatingText(
                  rating: diaDiem.diemTrungBinh,
                  iconSize: 20,
                  fontSize: 14,
                ),
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
                  '${diaDiem.soLuotThich} bài viết, 200 lượt thích',
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
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.placeReview,
                arguments: diaDiem.maDiaDiem,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _reviews(DiaDiemModel diaDiem) {
    return ListenableBuilder(
      listenable: KhoDanhGiaDiaDiem.instance,
      builder: (context, _) {
        final reviews = KhoDanhGiaDiaDiem.instance
            .danhSachTheoDiaDiem(diaDiem.maDiaDiem)
            .take(3)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text.rich(
              TextSpan(
                text: 'Xem tất cả đánh giá ',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: '(mặc định hiển thị 3)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ...reviews.map((item) => ReviewTile(review: item)),
          ],
        );
      },
    );
  }
}
