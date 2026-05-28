import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'trang_thongbao_nguoitheodoi.dart';
import '../../../messages/presentation/pages/trang_tinnhan.dart';
import 'package:do_an/app/routes/app_routes.dart';

class ActionNotifData {
  final String type;
  final bool isGoMateLogo;
  final String boldText1;
  final String normalText;
  final String boldText2;
  final String subtitle;

  const ActionNotifData({
    required this.type,
    this.isGoMateLogo = false,
    required this.boldText1,
    required this.normalText,
    this.boldText2 = '',
    required this.subtitle,
  });
}

class RecentNotifData {
  final bool isGoMateLogo;
  final String name;
  final String action;
  final String target;
  final int trailingType;
  final String? avatarPath;

  const RecentNotifData({
    this.isGoMateLogo = false,
    required this.name,
    required this.action,
    required this.target,
    required this.trailingType,
    this.avatarPath,
  });
}

const List<ActionNotifData> mockActionNotifs = [
  ActionNotifData(
    type: 'follow',
    boldText1: 'thuw + 5 người khác ',
    normalText: 'đã theo dõi bạn và ',
    boldText2: '5 gợi ý kết bạn',
    subtitle: '',
  ),
  ActionNotifData(
    type: 'message', // Giờ bấm cái này sẽ nhảy qua Tin Nhắn
    boldText1: 'thuw + 5 người khác ',
    normalText: 'đã gửi cho bạn tin nhắn',
    subtitle: '',
  ),
  ActionNotifData(
    type: 'itinerary',
    boldText1: 'Lịch trình kế tiếp',
    normalText: '',
    subtitle: 'Biển sơn trà - 15:00',
  ),
  ActionNotifData(
    type: 'suggestion',
    isGoMateLogo: true,
    boldText1: 'Bạn có muốn đến những địa điểm này không.',
    normalText: '',
    subtitle: '',
  ),
];

const List<RecentNotifData> mockRecentNotifs = [
  RecentNotifData(
    name: 'thuw ',
    action: 'đã bình luận bài viết: ',
    target: '"AAAAA"',
    trailingType: 0,
    avatarPath: 'assets/images/anh1.jpg',
  ),
  RecentNotifData(
    name: 'thuw ',
    action: 'đã thả cảm xúc với khoảnh khắc',
    target: '',
    trailingType: 0,
    avatarPath: 'assets/images/anh2.jpg',
  ),
  RecentNotifData(
    name: 'thuwwwww ',
    action: 'đã theo dõi bạn',
    target: '',
    trailingType: 1,
  ),
  RecentNotifData(
    isGoMateLogo: true,
    name: 'Bạn muốn đến ',
    action: '',
    target: 'Bán đảo sơn trà không',
    trailingType: 2,
  ),
];

class TrangThongBaoPage extends StatelessWidget {
  const TrangThongBaoPage({super.key});

  static const Color blue = Color(0xFF4AA8FF);
  static const String fontFamily = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    ...mockActionNotifs.map((item) => _actionPill(context, item)).toList(),
                    const SizedBox(height: 24),
                    const Text(
                      'Một tuần qua',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...mockRecentNotifs.map((item) => _recentItem(item)).toList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          InkWell(
            // === ĐÃ SỬA: BẤM < LÀ VỀ THẲNG TRANG CHỦ ===
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 24),
            ),
          ),
          const Expanded(
            child: Text(
              'Xuthu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _actionPill(BuildContext context, ActionNotifData data) {
    return InkWell(
      onTap: () {
        if (data.type == 'follow') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TrangNguoiTheoDoiPage()));
        }
        // === ĐÃ MỞ LẠI: BẤM TYPE MESSAGE SẼ QUA TRANG TIN NHẮN ===
        else if (data.type == 'message') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TrangTinNhanPage()));
        }
      },
      borderRadius: BorderRadius.circular(40),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: const Color(0xFF333333), width: 1.5),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            _leadingAvatar(data.isGoMateLogo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontFamily: fontFamily, fontSize: 14, color: Colors.white, height: 1.3),
                      children: [
                        TextSpan(text: data.boldText1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: data.normalText),
                        if (data.boldText2.isNotEmpty)
                          TextSpan(text: data.boldText2, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (data.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(data.subtitle, style: const TextStyle(fontFamily: fontFamily, fontSize: 13, color: Colors.white70)),
                  ]
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _recentItem(RecentNotifData data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _leadingAvatar(data.isGoMateLogo),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontFamily: fontFamily, fontSize: 14, color: Colors.white, height: 1.3),
                children: [
                  TextSpan(text: data.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: data.action),
                  if (data.target.isNotEmpty)
                    TextSpan(text: data.target, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildTrailing(data),
        ],
      ),
    );
  }

  Widget _leadingAvatar(bool isGoMate) {
    if (isGoMate) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.broken_image, color: Colors.white, size: 20));
          },
        ),
      );
    }
    return const CircleAvatar(radius: 20, backgroundColor: blue);
  }

  Widget _buildTrailing(RecentNotifData data) {
    if (data.trailingType == 0 && data.avatarPath != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset(data.avatarPath!, width: 40, height: 40, fit: BoxFit.cover));
    } else if (data.trailingType == 1 || data.trailingType == 2) {
      return Container(
        width: 115, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(20)),
        child: Text(data.trailingType == 1 ? 'Theo dõi lại' : 'Xem điểm đến', style: const TextStyle(fontFamily: fontFamily, color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      );
    }
    return const SizedBox.shrink();
  }
}