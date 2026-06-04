import '../models/user_profile_model.dart';

final mockUsers = {
  'Buji': const UserProfileModel(
    userName: 'Buji',
    fullName: 'Họ Tên',
    isFollowing: true,
    isPrivate: false,
    followerCount: 4,
    friendCount: 4,
    bio: '',
  ),

  'BongAnhHung': const UserProfileModel(
    userName: 'BongAnhHung',
    fullName: 'Họ Tên',
    isFollowing: false,
    isPrivate: true,
    followerCount: 4,
    friendCount: 4,
    bio: '',
  ),

  'Thuw': const UserProfileModel(
    userName: 'Thuw',
    fullName: 'Thư Thư',
    isFollowing: false,
    isPrivate: true,
    followerCount: 20,
    friendCount: 3,
    bio: '',
  ),

  'MinhAnh': const UserProfileModel(
    userName: 'MinhAnh',
    fullName: 'Minh Anh',
    isFollowing: false,
    isPrivate: false,
    followerCount: 12,
    friendCount: 8,
    bio: '',
  ),

  'BaoNgoc': const UserProfileModel(
    userName: 'BaoNgoc',
    fullName: 'Bảo Ngọc',
    isFollowing: false,
    isPrivate: false,
    followerCount: 35,
    friendCount: 14,
    bio: '',
  ),

  'HoangLong': const UserProfileModel(
    userName: 'HoangLong',
    fullName: 'Hoàng Long',
    isFollowing: false,
    isPrivate: true,
    followerCount: 18,
    friendCount: 5,
    bio: '',
  ),
};
final mockSuggestions = [
  'MinhAnh',
  'BaoNgoc',
  'HoangLong',
];
final mockFollowers = [
  'Thuw',
  'BongAnhHung',
  'Buji',
];

final mockFriends = [
  'Buji',
  'BongAnhHung',
];
