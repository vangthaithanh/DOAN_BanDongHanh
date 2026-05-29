import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/mock/mock_messages.dart';
import 'trang_tinnhan_caidat.dart';
class TrangDoanChatPage extends StatefulWidget {
  final String name;
  final bool isWaiting;

  const TrangDoanChatPage({
    super.key,
    required this.name,
    required this.isWaiting,
  });

  @override
  State<TrangDoanChatPage> createState() => _TrangDoanChatPageState();
}

class _TrangDoanChatPageState extends State<TrangDoanChatPage>
    with TickerProviderStateMixin {
  late bool _showWaitingActions;
  bool _hasText = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Ghi âm
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  late AnimationController _micBlinkAnim;

  // Sticker panel
  bool _showStickerPanel = false;

  late List<MessageModel> _currentMessages;

  @override
  void initState() {
    super.initState();
    _showWaitingActions = widget.isWaiting;
    _currentMessages = allChatsData[widget.name] ?? [];

    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });

    _micBlinkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _micBlinkAnim.dispose();
    super.dispose();
  }

  //  Scroll

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Gửi tin nhắn văn bản

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _currentMessages.add(
        MessageModel(
          text: text,
          isMe: true,
          type: MessageType.text,
        ),
      );
      _updateChatPreview();
      _textController.clear();
    });
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }
  void _updateChatPreview() {
    final index = normalMessages.indexWhere(
          (e) => e.name == widget.name,
    );

    if (index != -1) {
      normalMessages[index].lastMessage =
          getLastMessageText(widget.name);

      normalMessages[index].isUnread = false;
    }
  }
  // Máy ảnh (chụp ảnh / quay video trực tiếp)
  Future<void> _openCamera() async {
    final camStatus = await Permission.camera.request();
    if (!camStatus.isGranted) {
      _showPermissionDialog('Camera');
      return;
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Colors.white, size: 22),
              title: const Text('Chụp ảnh',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () async {
                Navigator.pop(context);
                final xFile =
                await ImagePicker().pickImage(source: ImageSource.camera);
                if (xFile != null && mounted) {
                  setState(() {
                    _currentMessages.add(
                      MessageModel(
                        text: xFile.path,
                        isMe: true,
                        type: MessageType.image,
                      ),
                    );
                    _updateChatPreview();
                  });

                  Future.delayed(
                    const Duration(milliseconds: 50),
                    _scrollToBottom,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.video, color: Colors.white, size: 22),
              title: const Text('Quay video',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () async {
                Navigator.pop(context);
                final xFile =
                await ImagePicker().pickVideo(source: ImageSource.camera);
                if (xFile != null && mounted) {
                  setState(() { _currentMessages.add(
                      MessageModel( text: xFile.path, isMe: true, type: MessageType.video,
                      ),
                    );
                    _updateChatPreview();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Gallery (ảnh / video từ máy)

  Future<void> _openGallery() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      _showPermissionDialog('Thư viện ảnh');
      return;
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Colors.white, size: 22),
              title: const Text('Gửi ảnh',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () async {
                Navigator.pop(context);
                final xFile =
                await ImagePicker().pickImage(source: ImageSource.gallery);
                if (xFile != null && mounted) {
                  setState(() { _currentMessages.add(MessageModel(
                      text: xFile.path, isMe: true, type: MessageType.image));
                  _updateChatPreview();
                  });
                  Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.film, color: Colors.white, size: 22),
              title: const Text('Gửi video',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () async {
                Navigator.pop(context);
                final xFile =
                await ImagePicker().pickVideo(source: ImageSource.gallery);
                if (xFile != null && mounted) {
                  setState(() {_currentMessages.add(MessageModel(
                      text: xFile.path, isMe: true, type: MessageType.video));
                  _updateChatPreview();
                  });
                  Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Ghi âm

  Future<void> _toggleRecording() async {
    _isRecording ? await _stopRecording() : await _startRecording();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showPermissionDialog('Microphone');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });
    _tickDuration();
  }

  void _tickDuration() async {
    while (_isRecording && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() => _recordDuration += const Duration(seconds: 1));
      }
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path != null && mounted) {
      setState(() { _currentMessages.add(
          MessageModel(text: path, isMe: true, type: MessageType.audio));
      _updateChatPreview();
      });
      Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
    }
  }

  Future<void> _cancelRecording() async {
    await _recorder.cancel();
    setState(() => _isRecording = false);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  //GPS vị trí thực

  Future<void> _sendGpsLocation() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      _showPermissionDialog('Vị trí');
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _currentMessages.add(MessageModel(
          text:
          'Vị trí: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude
              .toStringAsFixed(5)}',
          isMe: true,
          type: MessageType.location,
        ));
        _updateChatPreview();
      });
      Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không lấy được vị trí: $e')));
      }
    }
  }

  // Sticker

  void _toggleStickerPanel() {
    setState(() {
      _showStickerPanel = !_showStickerPanel;
      if (_showStickerPanel) _focusNode.unfocus();
    });
  }

  void _sendSticker(String emoji) {
    setState(() {
      _currentMessages.add(
          MessageModel(text: emoji, isMe: true, type: MessageType.sticker));
      _showStickerPanel = false;
      _updateChatPreview();
    });
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  // Permission dialog

  void _showPermissionDialog(String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text('Cần quyền $feature',
            style: const TextStyle(color: Colors.white)),
        content: Text(
          'Vui lòng cấp quyền $feature trong Cài đặt để dùng tính năng này.',
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Mở Cài đặt',
                style: TextStyle(color: Color(0xFF4AA8FF))),
          ),
        ],
      ),
    );
  }

  //  Logic chờ / chấp nhận
  void _handleAccept() {
    final existInWaiting =
    waitingMessages.any((e) => e.name == widget.name);
    if (existInWaiting) {
      final targetChat =
      waitingMessages.firstWhere((e) => e.name == widget.name);
      normalMessages.add(ChatData(
        name: targetChat.name,
        lastMessage: getLastMessageText(
          widget.name,
        ),
        time: targetChat.time,
        isUnread: false,
      ));
      waitingMessages.remove(targetChat);
    }
    setState(() => _showWaitingActions = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Đã chấp nhận cuộc trò chuyện!'),
          duration: Duration(seconds: 1)),
    );
  }

  void _handleBlockOrDelete(String action) {
    waitingMessages.removeWhere((e) => e.name == widget.name);
    Navigator.pop(context);
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft,
              color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrangTinNhanCaiDatPage(
                  name: widget.name,
                ),
              ),
            );
        if (mounted) {
        setState(() {});
        }
          },
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF4AA8FF),
              ),
              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nicknames[widget.name] ??
                        widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Họ tên',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),

              const Icon(
                LucideIcons.chevronRight,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(LucideIcons.phone, color: Colors.white),
              onPressed: () {}),
          IconButton(
              icon: const Icon(LucideIcons.video, color: Colors.white),
              onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            '18:20, TH 5',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Danh sách tin nhắn
          Expanded(
            child: GestureDetector(
              onTap: () {
                _focusNode.unfocus();
                if (_showStickerPanel) setState(() => _showStickerPanel = false);
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _currentMessages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _currentMessages.length) {
                    return const Padding(
                      padding:
                      EdgeInsets.only(top: 6, bottom: 12, right: 12),
                      child: Text(
                        'Đã xem vào Thứ Năm',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    );
                  }
                  return _buildChatBubble(_currentMessages[index]);
                },
              ),
            ),
          ),

          // Thanh ghi âm đang chạy
          if (_isRecording) _buildRecordingBar(),

          // Input / Waiting bar
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: 1.0,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _showWaitingActions
                ? _buildWaitingBottomBar()
                : _buildChatInputBottomBar(),
          ),

          // Panel sticker
          if (_showStickerPanel && !_showWaitingActions) _buildStickerPanel(),
        ],
      ),
    );
  }

  // Bubbles

  Widget _buildChatBubble(MessageModel message) {
    switch (message.type) {
      case MessageType.image:
        return _imageBubble(message);
      case MessageType.video:
        return _videoBubble(message);
      case MessageType.audio:
        return _audioBubble(message);
      case MessageType.sticker:
        return _stickerBubble(message);
      case MessageType.location:
        return _locationBubble(message);
      default:
        return _textBubble(message);
    }
  }

  Widget _bubbleRow({required bool isMe, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
                radius: 14, backgroundColor: Color(0xFF4AA8FF)),
            const SizedBox(width: 8),
          ],
          child,
        ],
      ),
    );
  }

  Widget _textBubble(MessageModel msg) => _bubbleRow(
    isMe: msg.isMe,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: const Color(0xFF2C2C2E), width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(msg.text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
    ),
  );

  Widget _locationBubble(MessageModel msg) => _bubbleRow(
    isMe: msg.isMe,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF444446),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(msg.text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          const Icon(LucideIcons.mapPin, color: Colors.white, size: 16),
        ],
      ),
    ),
  );

  Widget _imageBubble(MessageModel msg) => _bubbleRow(
    isMe: msg.isMe,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(msg.text),
        width: 200, height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _mediaErrorBox(),
      ),
    ),
  );

  Widget _videoBubble(MessageModel msg) => _bubbleRow(
    isMe: msg.isMe,
    child: Container(
      width: 200, height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
          child: Icon(LucideIcons.play, color: Colors.white, size: 44)),
    ),
  );

  Widget _audioBubble(MessageModel msg) => _bubbleRow(
    isMe: msg.isMe,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _audioPlayer.play(DeviceFileSource(msg.text)),
            child: const Icon(LucideIcons.play,
                color: Color(0xFF4AA8FF), size: 28),
          ),
          const SizedBox(width: 10),
          const Icon(LucideIcons.mic, color: Colors.white54, size: 16),
          const SizedBox(width: 4),
          const Text('Tin nhắn thoại',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    ),
  );

  Widget _stickerBubble(MessageModel msg) => _bubbleRow(
    isMe: msg.isMe,
    child: Text(msg.text, style: const TextStyle(fontSize: 48)),
  );

  Widget _mediaErrorBox() => Container(
    width: 200, height: 100,
    decoration: BoxDecoration(
      color: const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(
        child: Icon(LucideIcons.imageOff, color: Colors.white38, size: 32)),
  );

  // ── Recording bar ─────────────────────────────────────────

  Widget _buildRecordingBar() {
    return Container(
      color: const Color(0xFF1F1F1F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          FadeTransition(
            opacity: _micBlinkAnim,
            child: Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Text('Đang ghi âm  ${_formatDuration(_recordDuration)}',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.trash2,
                color: Colors.redAccent, size: 20),
            onPressed: _cancelRecording,
            tooltip: 'Hủy',
          ),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4AA8FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Gửi',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Waiting bottom bar (giữ nguyên) ──────────────────────

  Widget _buildWaitingBottomBar() {
    return Container(
      key: const ValueKey('waiting_bar'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 34),
      decoration: const BoxDecoration(
        color: Colors.black,
        border:
        Border(top: BorderSide(color: Color(0xFF222222), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chấp nhận tin nhắn đang chờ của\n${widget.name} (họ tên)?',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.3),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nếu bạn chấp nhận, họ có thể gọi cho bạn, xem được trạng thái hoạt động và thời điểm bạn đọc tin nhắn',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white60, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildActionButton('Chặn', const Color(0xFF2C2C2E),
                  Colors.white, () => _handleBlockOrDelete('Chặn')),
              const SizedBox(width: 10),
              _buildActionButton('Xóa', const Color(0xFF2C2C2E),
                  Colors.white, () => _handleBlockOrDelete('Xóa')),
              const SizedBox(width: 10),
              _buildActionButton('Chấp nhận',
                  const Color(0xFF2481CC), Colors.white, _handleAccept),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chat input bottom bar ─────────────────────────────────

  Widget _buildChatInputBottomBar() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      key: const ValueKey('chat_input_bar'),
      padding:
      EdgeInsets.fromLTRB(12, 8, 12, bottomInset > 0 ? 8 : 24),
      color: Colors.black,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            // 1. Máy ảnh
            IconButton(
              icon: const Icon(LucideIcons.camera,
                  color: Colors.white, size: 24),
              onPressed: _openCamera,
            ),

            // 2. Soạn tin nhắn
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                onTap: () {
                  if (_showStickerPanel) {
                    setState(() => _showStickerPanel = false);
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Nhắn tin...',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _hasText
              // Nút gửi text
                  ? IconButton(
                key: const ValueKey('send_btn'),
                icon: const Icon(LucideIcons.sendHorizontal,
                    color: Color(0xFF4AA8FF), size: 24),
                onPressed: _sendMessage,
              )
              // 3-4-5-6: Mic / Gallery / Sticker / Vị trí
                  : Row(
                key: const ValueKey('actions_icons'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 3. Ghi âm
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: Icon(
                      LucideIcons.mic,
                      color: _isRecording
                          ? Colors.redAccent
                          : Colors.white,
                      size: 24,
                    ),
                    onPressed: _toggleRecording,
                  ),
                  // 4. Gallery
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(LucideIcons.image,
                        color: Colors.white, size: 24),
                    onPressed: _openGallery,
                  ),
                  // 5. Nhãn dán
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: Icon(
                      LucideIcons.smile,
                      color: _showStickerPanel
                          ? const Color(0xFF4AA8FF)
                          : Colors.white,
                      size: 24,
                    ),
                    onPressed: _toggleStickerPanel,
                  ),
                  // 6. Vị trí
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(LucideIcons.mapPin,
                        color: Colors.white, size: 24),
                    onPressed: _sendGpsLocation,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sticker panel ─────────────────────────────────────────

  Widget _buildStickerPanel() {
    const stickers = [
      '😂', '❤️', '👍', '🎉', '😍', '🔥',
      '😢', '😎', '🥰', '🤣', '😡', '👋',
      '🐶', '🐱', '🦊', '🐸', '🐼', '🦋',
      '🍕', '🍦', '🎂', '🍜', '🌮', '🧋',
    ];

    return Container(
      height: 200,
      color: const Color(0xFF1F1F1F),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: stickers.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _sendSticker(stickers[i]),
          child: Center(
              child: Text(stickers[i],
                  style: const TextStyle(fontSize: 30))),
        ),
      ),
    );
  }

  // ── Action button (giữ nguyên) ────────────────────────────

  Widget _buildActionButton(
      String label, Color bgColor, Color textColor, VoidCallback onPressed) {
    return Expanded(
      child: SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}