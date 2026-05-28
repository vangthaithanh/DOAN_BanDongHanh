import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NutChonNguoiXem extends StatelessWidget {
  final VoidCallback onTap;

  const NutChonNguoiXem({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mọi người',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuNguoiXem extends StatelessWidget {
  const MenuNguoiXem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 226,
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dongDau(),
          _dongNguoiDung('BongAnhHung'),
          _dongNguoiDung('Buji'),
          const SizedBox(height: 78),
        ],
      ),
    );
  }

  Widget _dongDau() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            LucideIcons.userRound,
            color: Colors.white,
            size: 15,
          ),
          SizedBox(width: 16),
          Text(
            'Mọi người',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dongNguoiDung(String ten) {
    return Container(
      height: 39,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 8,
            backgroundColor: Color(0xFF4AA8FF),
          ),
          const SizedBox(width: 14),
          Text(
            ten,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}