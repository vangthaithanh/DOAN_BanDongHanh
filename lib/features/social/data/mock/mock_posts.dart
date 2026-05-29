import '../models/post_model.dart';

final List<PostModel> mockPosts = [
  PostModel(
    id: 1,
    tenNguoiDang: 'BongAnhHung',
    thoiGian: '3 ngày trước',
    caption: 'Chuyến đi tuyệt vời ở Đà Nẵng!',
    danhSachAnh: [
      'assets/images/anh1.jpg',
      'assets/images/anh2.jpg',
    ],
    viTri: 'Bãi biển Mỹ Khê, Đà Nẵng',
    danhSachHashTag: ['DaNang', 'DuLich'],
    soLuotThich: 24,
    soLuotBinhLuan: 3,
    laBaiVietCuaToi: false,
  ),
  PostModel(
    id: 2,
    tenNguoiDang: 'Buji',
    thoiGian: '1 ngày trước',
    caption: 'Cà phê sáng ở Hội An 🌿',
    danhSachAnh: [
      'assets/images/anh3.jpg',
    ],
    viTri: 'Hội An, Quảng Nam',
    danhSachHashTag: ['HoiAn', 'CaPhe'],
    soLuotThich: 11,
    soLuotBinhLuan: 1,
    laBaiVietCuaToi: false,
  ),
  PostModel(
    id: 3,
    tenNguoiDang: 'BongAnhHung',
    thoiGian: '5 giờ trước',
    caption: null,
    danhSachAnh: [
      'assets/images/anh1.jpg',
    ],
    viTri: null,
    danhSachHashTag: [],
    soLuotThich: 5,
    soLuotBinhLuan: 0,
    laBaiVietCuaToi: false,
  ),
];