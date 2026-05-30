import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/dia_diem_model.dart';

class PlaceImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const PlaceImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      image = Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorBox(),
      );
    } else if (path.startsWith('assets/')) {
      image = Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorBox(),
      );
    } else {
      image = Image.file(
        File(path),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorBox(),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        child: image,
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2B2B2B),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white54,
      ),
    );
  }
}

class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFF3A3A3A),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class BluePillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double height;
  final EdgeInsets padding;

  const BluePillButton({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 30,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          padding: padding,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class RatingText extends StatelessWidget {
  final double rating;
  final double iconSize;
  final double fontSize;

  const RatingText({
    super.key,
    required this.rating,
    this.iconSize = 18,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_border_rounded,
          color: AppColors.primary,
          size: iconSize,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1).replaceAll('.', ','),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class PlaceInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const PlaceInfoLine({
    super.key,
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceCard extends StatelessWidget {
  final DiaDiemModel diaDiem;
  final VoidCallback? onTap;

  const PlaceCard({super.key, required this.diaDiem, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          onTap ??
          () {
            Navigator.pushNamed(
              context,
              AppRoutes.placeDetail,
              arguments: diaDiem.maDiaDiem,
            );
          },
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlaceImage(
              path: diaDiem.hinhAnh.first,
              width: 126,
              height: 140,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            diaDiem.tenDiaDiem,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        RatingText(rating: diaDiem.diemTrungBinh),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PlaceInfoLine(
                      icon: Icons.location_on_outlined,
                      text: diaDiem.khoangCach,
                    ),
                    PlaceInfoLine(
                      icon: Icons.location_on_outlined,
                      text: diaDiem.diaChiHienThi,
                      maxLines: 2,
                    ),
                    PlaceInfoLine(
                      icon: Icons.paid_outlined,
                      text: 'Số tiền trung bình (${diaDiem.giaTrungBinh})',
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: BluePillButton(
                            text: 'Đánh giá',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.placeReview,
                                arguments: diaDiem.maDiaDiem,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BluePillButton(
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewTile extends StatelessWidget {
  final DanhGiaDiaDiemModel review;
  final bool showImages;

  const ReviewTile({super.key, required this.review, this.showImages = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.tenNguoiDung,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      review.ngayThang,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              RatingText(rating: review.diem),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              review.noiDungHienThi,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showImages && review.hinhAnh.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 42),
                scrollDirection: Axis.horizontal,
                itemCount: review.hinhAnh.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  return PlaceImage(
                    path: review.hinhAnh[index],
                    width: 126,
                    height: 130,
                    borderRadius: BorderRadius.circular(8),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
