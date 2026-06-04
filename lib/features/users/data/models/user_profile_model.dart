class UserProfileModel {
  final String userName;
  final String fullName;

  final bool isFollowing;
  final bool isPrivate;

  final int followerCount;
  final int friendCount;

  final String bio;

  const UserProfileModel({
    required this.userName,
    required this.fullName,
    required this.isFollowing,
    required this.isPrivate,
    required this.followerCount,
    required this.friendCount,
    required this.bio,
  });
}