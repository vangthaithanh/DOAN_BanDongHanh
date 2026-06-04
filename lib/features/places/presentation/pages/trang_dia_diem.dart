import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../data/mock/mock_dia_diem.dart';
import '../widgets/place_common_widgets.dart';

class TrangDiaDiemPage extends StatelessWidget {
  const TrangDiaDiemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                children: [
                  _header(context),
                  const SizedBox(height: 18),
                  _searchAndFilter(),
                  const SizedBox(height: 12),
                  _filterChips(),
                  const SizedBox(height: 24),
                  const Text.rich(
                    TextSpan(
                      text: 'Đề xuất ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: '(theo tiêu chí gần định vị & đang hot)',
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
                  ...mockDiaDiems.map(
                    (item) => PlaceCard(
                      diaDiem: item,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.placeDetail,
                          arguments: item.maDiaDiem,
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
        const Icon(Icons.map_outlined, color: Colors.white, size: 28),
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
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B3B3B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Tìm Kiếm',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChips() {
    const chips = [
      'Tỉnh thành',
      'Khoảng cách',
      'Tiêu chí',
      'Đánh giá',
      'Số tiền',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((text) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B3B3B),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }).toList(),
    );
  }
}
