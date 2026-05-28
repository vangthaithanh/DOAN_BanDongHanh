import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import 'main_tab.dart';

class AppBottomNav extends StatelessWidget {
  final MainTab activeTab;

  const AppBottomNav({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(
              icon: LucideIcons.house,
              active: activeTab == MainTab.home,
              onTap: () => _go(context, AppRoutes.home),
            ),
            _NavIcon(
              icon: LucideIcons.aperture,
              active: activeTab == MainTab.moments,
              onTap: () => _go(context, AppRoutes.momentCamera),
            ),
            _NavIcon(
              icon: LucideIcons.mapPin,
              active: activeTab == MainTab.map,
              onTap: () => _go(context, AppRoutes.map),
            ),
            _NavIcon(
              icon: LucideIcons.messagesSquare,
              active: activeTab == MainTab.messages,
              onTap: () => _go(context, AppRoutes.messages),
            ),
            _NavIcon(
              icon: LucideIcons.userRound,
              active: activeTab == MainTab.profile,
              onTap: () => _go(context, AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String routeName) {
    if (ModalRoute.of(context)?.settings.name == routeName) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: active ? AppColors.primaryDark : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
