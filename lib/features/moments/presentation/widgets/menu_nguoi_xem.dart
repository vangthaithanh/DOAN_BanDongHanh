import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NutChonNguoiXem extends StatelessWidget {
  final VoidCallback onTap;
  final String tenHienTai;

  const NutChonNguoiXem({
    super.key,
    required this.onTap,
    this.tenHienTai = 'Mọi người',
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tenHienTai,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
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
  final List<Map<String, dynamic>> danhSachProfiles;
  final Function(Map<String, dynamic>?) onProfileSelected;

  const MenuNguoiXem({
    super.key,
    required this.danhSachProfiles,
    required this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 226,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dongMoiNguoi(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: danhSachProfiles.length,
              itemBuilder: (context, index) {
                return _dongNguoiDung(danhSachProfiles[index]);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _dongMoiNguoi() {
    return InkWell(
      onTap: () => onProfileSelected(null),
      child: Container(
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
      ),
    );
  }

  Widget _dongNguoiDung(Map<String, dynamic> profile) {
    final ten = profile['nickname'] ?? profile['full_name'] ?? 'Người dùng';
    final avatar = profile['avatar_url']?.toString() ?? '';

    return InkWell(
      onTap: () => onProfileSelected(profile),
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white24, width: 1),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF4AA8FF),
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty ? const Icon(Icons.person, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                ten,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
