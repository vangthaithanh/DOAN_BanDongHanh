String timeAgo(DateTime createdAt) {
  final now = DateTime.now();
  final normalizedCreatedAt = _normalizeFutureLocalTimestamp(createdAt, now);
  final diff = now.difference(normalizedCreatedAt);

  if (diff.isNegative || diff.inSeconds < 5) return 'Vừa xong';
  if (diff.inSeconds < 60) return '${diff.inSeconds} giây trước';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 30) return '${diff.inDays} ngày trước';

  final months = diff.inDays ~/ 30;
  if (months < 12) return '$months tháng trước';

  return '${diff.inDays ~/ 365} năm trước';
}

DateTime _normalizeFutureLocalTimestamp(DateTime createdAt, DateTime now) {
  final diff = now.difference(createdAt);

  if (!diff.isNegative) {
    return createdAt;
  }

  final localOffset = now.timeZoneOffset;

  if (localOffset == Duration.zero) {
    return createdAt;
  }

  final shifted = createdAt.subtract(localOffset);
  final shiftedDiff = now.difference(shifted);

  if (!shiftedDiff.isNegative || shiftedDiff.abs() < diff.abs()) {
    return shifted;
  }

  return createdAt;
}
