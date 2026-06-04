String timeAgo(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);

  if (diff.inSeconds < 5) return 'Vừa xong';
  if (diff.inSeconds < 60) return '${diff.inSeconds} giây trước';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 30) return '${diff.inDays} ngày trước';

  final months = diff.inDays ~/ 30;
  if (months < 12) return '$months tháng trước';

  return '${diff.inDays ~/ 365} năm trước';
}
