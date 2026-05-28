import '../models/post_model.dart';

const List<PostModel> mockPosts = [
  PostModel(
    id: 1,
    authorName: 'Buj',
    locationName: 'Vị trí (chỗ này để địa điểm nếu có)',
    nearText: 'Gắn hashtag nếu có (gắn đề dựa trên đây đề xuất bài viết)',
    caption: 'Caption',
    mediaUrls: [
      'assets/images/anh1.jpg',
      'assets/images/anh2.jpg',
      'assets/images/anh3.jpg',
    ],
    likeCount: 4,
    commentCount: 4,
    shareCount: 1,
    isLiked: true,
  ),
  PostModel(
    id: 2,
    authorName: 'BongAnhHung',
    locationName: 'Đà Lạt',
    nearText: '#dulich #checkin',
    caption: 'Đi chơi cuối tuần',
    mediaUrls: [
      'assets/images/anh1.jpg',
      'assets/images/anh2.jpg',
    ],
    likeCount: 7,
    commentCount: 3,
    shareCount: 2,
    isLiked: false,
  ),
];

PostModel timBaiVietTheoId(int id) {
  return mockPosts.firstWhere(
        (post) => post.id == id,
    orElse: () => mockPosts.first,
  );
}