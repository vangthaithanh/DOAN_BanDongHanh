import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'trang_thongbao.dart';

class ChatData {
  final String name;
  final String lastMessage;
  final String time;
  final bool isUnread;

  const ChatData({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.isUnread = false,
  });
}

const List<ChatData> mockChats = [
  ChatData(name: 'Buji', lastMessage: 'ChatChatChat', time: '3 ngày', isUnread: true),
  ChatData(name: 'BongAnhHung', lastMessage: 'ChatChat', time: '3 ngày', isUnread: false),
];

class TrangTinNhanPage extends StatelessWidget {
  const TrangTinNhanPage({super.key});

  static const Color blue = Color(0xFF4AA8FF);
  static const String fontFamily = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            _searchBar(),
            _tabHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mockChats.length,
                itemBuilder: (context, index) {
                  return _chatCard(mockChats[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  // --- CÁC COMPONENT CON ---
  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ĐÃ XÓA NÚT <. Để 1 cái khoảng trống bằng cái chuông cho chữ Xuthu nằm ngay giữa
          const SizedBox(width: 24),
          const Text(
            'Xuthu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TrangThongBaoPage()));
            },
            child: const Icon(LucideIcons.bell, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 45,
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(25)),
        child: const TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm Kiếm',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
            prefixIcon: Icon(LucideIcons.search, color: Colors.white54, size: 18),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _tabHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Tin nhắn', style: TextStyle(fontFamily: fontFamily, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          Text('Tin nhắn đang chờ', style: TextStyle(fontFamily: fontFamily, color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _chatCard(ChatData chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.black, border: Border.all(color: const Color(0xFF333333), width: 1.5), borderRadius: BorderRadius.circular(40)),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundColor: blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chat.name, style: const TextStyle(fontFamily: fontFamily, color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(chat.lastMessage, style: const TextStyle(fontFamily: fontFamily, color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Row(
            children: [
              Text(chat.time, style: const TextStyle(fontFamily: fontFamily, color: Colors.white54, fontSize: 12)),
              if (chat.isUnread) ...[
                const SizedBox(width: 8),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: blue, shape: BoxShape.circle)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: Color(0xFF1E1E1E)))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/trang-chu',
                      (route) => false,
                );
              },
              child: const Icon(LucideIcons.house, color: Colors.white, size: 24),
            ),
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/'),
              child: const Icon(LucideIcons.aperture, color: Colors.white, size: 24),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/map');
              },
              child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 24),
            ),
            InkWell(
              onTap: () {},
              child: const Icon(LucideIcons.messagesSquare, color: Color(0xFF3E96D8), size: 24),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/trang-canhan');
              },
              child: const Icon(LucideIcons.userRound, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}