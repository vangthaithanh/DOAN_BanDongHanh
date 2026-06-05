class ChatData {
  final String name;
  String lastMessage;
  final String time;
  bool isUnread;

  ChatData({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.isUnread = false,
  });
}

enum MessageType { text, location, image, video, audio, sticker, momentReply, sharedPost }

class MessageModel {
  final int id;
  final String text;
  final bool isMe;
  final MessageType type;

  // Fields for Moment/Story Reply
  final String? momentId;
  final String? momentImageUrl;
  final String? momentOwnerName;
  final String? momentOwnerId;

  // Field for shared post
  final int? postId;

  const MessageModel({
    this.id = 0,
    required this.text,
    required this.isMe,
    this.type = MessageType.text,
    this.momentId,
    this.momentImageUrl,
    this.momentOwnerName,
    this.momentOwnerId,
    this.postId,
  });
}

List<ChatData> normalMessages = [
  ChatData(
    name: 'Buji',
    lastMessage: 'Bạn muốn đến đây không',
    time: '3 ngày',
    isUnread: true,
  ),
];

List<ChatData> waitingMessages = [
  ChatData(
    name: 'BongAnhHung',
    lastMessage: 'Bạn muốn đến đây không',
    time: '3 ngày',
  ),
];
Map<String, String> nicknames = {};

Map<String, List<MessageModel>> allChatsData = {
  'BongAnhHung': [
    const MessageModel(text: 'Bạn muốn đến đây không', isMe: false),
    const MessageModel(text: 'Xem vị trí', isMe: false, type: MessageType.location),
  ],
  'Buji': [
    const MessageModel(text: 'Bạn muốn đến đây không', isMe: false),
    const MessageModel(text: 'Bạn đi đâu thế', isMe: true),
    const MessageModel(text: 'Vị trí của bạn ở đâu ?????', isMe: true),
    const MessageModel(text: 'Xem vị trí', isMe: false, type: MessageType.location),
    const MessageModel(text: 'Đây này', isMe: false),
    const MessageModel(text: 'Tôi thấy rồi, bạn đợi nhé', isMe: true),
  ],
};

String getLastMessageText(String userName) {
  final messages = allChatsData[userName];
  if (messages == null || messages.isEmpty) return '';
  final last = messages.last;

  switch (last.type) {
    case MessageType.image:
      return '📷 Hình ảnh';
    case MessageType.video:
      return '🎥 Video';
    case MessageType.audio:
      return '🎤 Tin nhắn thoại';
    case MessageType.location:
      return '📍 Vị trí';
    case MessageType.sticker:
      return '😊 Sticker';
    case MessageType.momentReply:
      return '💬 Đã trả lời khoảnh khắc';
    case MessageType.sharedPost:
      return '📎 Đã chia sẻ một bài viết';
    case MessageType.text:
      return last.text;
  }
}
