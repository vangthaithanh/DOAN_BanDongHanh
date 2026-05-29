import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/mock/mock_messages.dart';

class TrangChatChoPage extends StatefulWidget {
  final String name;

  const TrangChatChoPage({
    super.key,
    required this.name,
  });

  @override
  State<TrangChatChoPage> createState() => _TrangChatChoPageState();
}

class _TrangChatChoPageState extends State<TrangChatChoPage> {
  bool _isAccepted = false; // Kiểm tra đã bấm chấp nhận chưa

  void _handleAccept() {
    // Tìm kiếm xem tin nhắn này có trong list chờ không
    final existInWaiting = waitingMessages.any((element) => element.name == widget.name);

    if (existInWaiting) {
      final targetChat = waitingMessages.firstWhere((element) => element.name == widget.name);

      // 1. Thêm vào danh sách tin nhắn chính thức
      normalMessages.add(targetChat);
      // 2. Xóa khỏi danh sách chờ
      waitingMessages.remove(targetChat);
    }

    setState(() {
      _isAccepted = true; // Chuyển trạng thái để đổi khung chat mượt mà bằng AnimatedSwitcher
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chấp nhận cuộc trò chuyện!'), duration: Duration(seconds: 1)),
    );
  }

  void _handleBlockOrDelete(String action) {
    waitingMessages.removeWhere((element) => element.name == widget.name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thực hiện: $action'), duration: const Duration(seconds: 1)),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(radius: 18, backgroundColor: Color(0xFF4AA8FF)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Họ tên',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 16),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.phone, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(LucideIcons.video, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            '18:20, TH 5',
            style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Vùng hiển thị tin nhắn (Giữ nguyên tin nhắn cũ của người kia gửi)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildChatBubble('Bạn muốn đến đây không'),
                _buildChatBubble('Bạn muốn đến đây không'),
              ],
            ),
          ),

          // Hiệu ứng hoán đổi mượt mà giữa thanh Chấp nhận và thanh Nhập tin nhắn đầy đủ chức năng
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: 1.0,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: !_isAccepted
                ? _buildWaitingBottomBar() // Nếu chưa chấp nhận: Hiện nút Chặn/Xóa/Chấp nhận
                : _buildChatInputBottomBar(), // Nếu đã chấp nhận: Hiện khung soạn thảo chuẩn thiết kế ảnh 3
          ),
        ],
      ),
    );
  }

  // Giao diện 1: Thanh Đợi chấp nhận tin nhắn
  Widget _buildWaitingBottomBar() {
    return Container(
      key: const ValueKey('waiting_bar'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 34),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF222222), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chấp nhận tin nhắn đang chờ của\n${widget.name} (họ tên)?',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nếu bạn chấp nhận, họ có thể gọi cho bạn, xem được trạng thái hoạt động và thời điểm bạn đọc tin nhắn',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildActionButton('Chặn', const Color(0xFF2C2C2E), Colors.white, () => _handleBlockOrDelete('Chặn')),
              const SizedBox(width: 10),
              _buildActionButton('Xóa', const Color(0xFF2C2C2E), Colors.white, () => _handleBlockOrDelete('Xóa')),
              const SizedBox(width: 10),
              _buildActionButton('Chấp nhận', const Color(0xFF2481CC), Colors.white, _handleAccept),
            ],
          ),
        ],
      ),
    );
  }

  // Giao diện 2: Thanh soạn thảo văn bản chuẩn mẫu ảnh mới sau khi đã chấp nhận
  Widget _buildChatInputBottomBar() {
    return Container(
      key: const ValueKey('chat_input_bar'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      child: Row(
        children: [
          // Nút bấm gửi ảnh/mở thư viện ảnh
          IconButton(
            icon: const Icon(LucideIcons.image, color: Colors.white70, size: 24),
            onPressed: () {},
          ),
          // Nút bấm vị trí định vị
          IconButton(
            icon: const Icon(LucideIcons.mapPin, color: Colors.white70, size: 24),
            onPressed: () {},
          ),
          // Khung nhập liệu văn bản tròn bo góc
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: const TextField(
                style: TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Nút ghi âm thoại
          IconButton(
            icon: const Icon(LucideIcons.mic, color: Colors.white70, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(radius: 14, backgroundColor: Color(0xFF4AA8FF)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: const Color(0xFF333333), width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color bgColor, Color textColor, VoidCallback onPressed) {
    return Expanded(
      child: SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}