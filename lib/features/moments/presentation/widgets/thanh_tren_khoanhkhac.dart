import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes/app_routes.dart';

class ThanhTrenKhoanhKhac extends StatelessWidget {
  const ThanhTrenKhoanhKhac({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 28,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Go',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: 'Mate',
                    style: TextStyle(
                      color: Color(0xFF4AA8FF),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 31,
            top: 24,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.notifications);
              },
              borderRadius: BorderRadius.circular(20),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  LucideIcons.bell,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}