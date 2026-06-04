class AppRoutes {
  const AppRoutes._();

  // Splash/start/auth
  static const String start = '/';
  static const String loginEmail = '/dangnhap-email';
  static const String loginPhone = '/dangnhap-sdt';
  static const String passwordEmail = '/matkhau-email';
  static const String passwordPhone = '/matkhau-sdt';
  static const String registerEmail = '/dangki-email';
  static const String registerPasswordEmail = '/dangki-matkhau-email';
  static const String registerNameEmail = '/dangki-ten-email';
  static const String registerPhone = '/dangki-sdt';
  static const String registerPasswordPhone = '/dangki-matkhau-sdt';
  static const String registerNamePhone = '/dangki-ten-sdt';
  static const String addAvatar = '/them-anh-daidien';
  static const String loading = '/man-hinh-cho';
  static const String quenMatKhauEmail = '/quen-mat-khau/email';
  static const String quenMatKhauSdt = '/quen-mat-khau/sdt';
  static const String quenMatKhauOtp = '/quen-mat-khau/otp';
  static const String quenMatKhauMoi = '/quen-mat-khau/moi';

  // Onboarding
  static const String surveyIntro = '/cau-hoi';
  static const String surveyQuestion1 = '/cau-hoi-1';
  static const String surveyQuestion2 = '/cau-hoi-2';
  static const String surveyQuestion3 = '/cau-hoi-3';

  // Main tabs
  static const String home = '/trang-chu';
  static const String map = '/map';
  static const String momentCamera = '/trang_chia_se_camera';
  static const String trangPreviewHinh = '/trang-preview-hinh';
  static const String trangGalleryKhoanhKhac = '/trang-gallery-khoanhkhac';
  static const String trangHinhAnhChiTiet = '/trang-hinh-anh-chi-tiet';
  static const String messages = '/trang-tinnhan';
  static const String profile = '/trang-canhan';
  static const String notifications = '/trang_thongbao';
  static const String trangViTri = '/trang-vi-tri';

  // Posts/social
  static const String createPost = '/bai-viet/tao';
  static const String postDetail = '/bai-viet/chi-tiet';
  static const String trangBinhLuan = '/trang-binhluan';

  // Places
  static const String search = '/tim-kiem';
  static const String placeList = '/dia-diem';
  static const String placeDetail = '/dia-diem/chi-tiet';
  static const String placeReview = '/dia-diem/danh-gia';

  // Trips
  static const String tripList = '/lich-trinh';
  static const String tripCreate = '/lich-trinh/tao';
  static const String tripDetail = '/lich-trinh/chi-tiet';

  // Profile/settings/friends
  static const String editProfile = '/ho-so/chinh-sua';
  static const String settings = '/cai-dat';
  static const String followRequests = '/theo-doi/yeu-cau';
  static const String friendSuggestions = '/ban-be/goi-y';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminReports = '/admin/bao-cao';

  // Messages
  static const String waitingMessages = '/trang-tinnhan-cho';
  static const String chatDetail = '/trang-doan-chat';
  static const String loginCallback = '/login-callback';
}
