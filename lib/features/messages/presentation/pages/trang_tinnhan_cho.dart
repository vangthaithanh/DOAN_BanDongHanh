import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:do_an/app/routes/app_routes.dart';
import '../../data/mock/mock_messages.dart';

class TrangTinNhanChoPage extends StatefulWidget {
  const TrangTinNhanChoPage({super.key});

  @override
  State<TrangTinNhanChoPage> createState() => _TrangTinNhanChoPageState();
}

class _TrangTinNhanChoPageState extends State<TrangTinNhanChoPage> {
  static const Color blue = Color(0xFF4AA8FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xuthu',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Text(
                'Tin nhắn đang chờ',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: waitingMessages.isEmpty
                  ? const Center(child: Text('Không có tin nhắn chờ', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                itemCount: waitingMessages.length,
                itemBuilder: (context, index) {
                  final chat = waitingMessages[index];
                  return GestureDetector(
                    onTap: () async {
                      // CHỖ SỬA CHÍNH NẰM Ở ĐÂY BRO ƠI!
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.chatDetail, // 1. Đổi sang route chat chung dùng chung cho 2 màn hình
                        arguments: {
                          'name': chat.name, // 2. Truyền tên người gửi
                          'isWaiting': true, // 3. Báo hiệu cho màn hình chat biết đây là tin nhắn CHỜ để hiện 3 nút Chặn/Xóa/Nhận
                        },
                      );
                      // Cập nhật lại giao diện danh sách khi quay lại (nếu đã ấn Chấp nhận/Xóa thì mục đó mất đi)
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: const Color(0xFF222222), width: 1.5),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 20, backgroundColor: blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  chat.lastMessage,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(chat.time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}