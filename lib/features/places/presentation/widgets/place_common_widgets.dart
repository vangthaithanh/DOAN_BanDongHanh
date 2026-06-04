import 'dart:io';

import 'package:flutter/foundation.dart';
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
    final cleanPath = path.trim();
    Widget image;

    if (cleanPath.isEmpty) {
      image = _errorBox();
    } else if (cleanPath.startsWith('http://') ||
        cleanPath.startsWith('https://')) {
      image = Image.network(
        cleanPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorBox(),
      );
    } else if (cleanPath.startsWith('assets/')) {
      image = Image.asset(
        cleanPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorBox(),
      );
    } else if (!kIsWeb) {
      image = Image.file(
        File(cleanPath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorBox(),
      );
    } else {
      image = _errorBox();
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFF2B2B2B),
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
        width: 36,
        height: 36,
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
    this.height = 32,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
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
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
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
        const SizedBox(width: 3),
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
  final double fontSize;

  const PlaceInfoLine({
    super.key,
    required this.icon,
    required this.text,
    this.maxLines = 1,
    this.fontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 15),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: fontSize,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final cardWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenWidth;
        final isSmall = cardWidth < 360;

        final imageWidth = (cardWidth * (isSmall ? 0.34 : 0.32))
            .clamp(102.0, 138.0)
            .toDouble();
        final imageHeight = (imageWidth * 1.18).clamp(124.0, 164.0).toDouble();
        final gap = isSmall ? 10.0 : 14.0;
        final titleSize = isSmall ? 14.2 : 15.2;
        final infoSize = isSmall ? 11.0 : 11.5;
        final buttonHeight = isSmall ? 30.0 : 32.0;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap ??
              () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.placeDetail,
                  arguments: diaDiem.maDiaDiem,
                );
              },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlaceImage(
                  path: diaDiem.hinhAnh.first,
                  width: imageWidth,
                  height: imageHeight,
                  borderRadius: BorderRadius.circular(8),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              diaDiem.tenDiaDiem,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                                height: 1.14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          RatingText(
                            rating: diaDiem.diemTrungBinh,
                            iconSize: isSmall ? 16 : 18,
                            fontSize: isSmall ? 12.5 : 13,
                          ),
                        ],
                      ),
                      SizedBox(height: isSmall ? 6 : 7),
                      PlaceInfoLine(
                        icon: Icons.location_on_outlined,
                        text: diaDiem.khoangCach,
                        fontSize: infoSize,
                      ),
                      PlaceInfoLine(
                        icon: Icons.location_on_outlined,
                        text: diaDiem.diaChiHienThi,
                        maxLines: isSmall ? 2 : 2,
                        fontSize: infoSize,
                      ),
                      PlaceInfoLine(
                        icon: Icons.paid_outlined,
                        text: 'Số tiền trung bình (${diaDiem.giaTrungBinh})',
                        fontSize: infoSize,
                      ),
                      SizedBox(height: isSmall ? 6 : 8),
                      Row(
                        children: [
                          Expanded(
                            child: BluePillButton(
                              text: 'Đánh giá',
                              height: buttonHeight,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.placeReview,
                                  arguments: diaDiem.maDiaDiem,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: BluePillButton(
                              text: 'Xem vị trí',
                              height: buttonHeight,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              onTap: () {
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
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ReviewTile extends StatelessWidget {
  final DanhGiaDiaDiemModel review;
  final bool showImages;

  const ReviewTile({super.key, required this.review, this.showImages = true});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final imageWidth = (screenWidth * 0.32).clamp(108.0, 132.0).toDouble();
    final imageHeight = (imageWidth * 0.96).clamp(104.0, 126.0).toDouble();

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
                child: Icon(Icons.person, color: Colors.white, size: 18),
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
          if (review.noiDungHienThi.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                review.noiDungHienThi,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
          if (showImages && review.hinhAnh.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: imageHeight,
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 42),
                scrollDirection: Axis.horizontal,
                itemCount: review.hinhAnh.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final imagePath = review.hinhAnh[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showImageViewer(context, imagePath),
                    child: PlaceImage(
                      path: imagePath,
                      width: imageWidth,
                      height: imageHeight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageViewer(BuildContext context, String imagePath) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.88),
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(14),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: PlaceImage(
                    path: imagePath,
                    width: double.infinity,
                    height: MediaQuery.sizeOf(context).height * 0.72,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
