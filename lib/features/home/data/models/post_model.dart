class PostModel {
  final int id;
  final String authorName;
  final String? authorAvatarUrl;
  final String? locationName;
  final String? nearText;
  final String caption;
  final List<String> mediaUrls;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;

  const PostModel({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    this.locationName,
    this.nearText,
    required this.caption,
    required this.mediaUrls,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
  });
}