import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../../core/widgets/coming_soon_page.dart';
import '../../features/auth/data/models/du_lieu_quen_matkhau.dart';
import '../../features/auth/presentation/pages/dangki_email.dart';
import '../../features/auth/presentation/pages/dangki_matkhau_email.dart';
import '../../features/auth/presentation/pages/dangki_matkhau_sdt.dart';
import '../../features/auth/presentation/pages/dangki_sdt.dart';
import '../../features/auth/presentation/pages/dangki_ten_email.dart';
import '../../features/auth/presentation/pages/dangki_ten_sdt.dart';
import '../../features/auth/presentation/pages/dangnhap_email.dart';
import '../../features/auth/presentation/pages/dangnhap_sdt.dart';
import '../../features/auth/presentation/pages/google_login_callback.dart';
import '../../features/auth/presentation/pages/man_hinh_cho.dart';
import '../../features/auth/presentation/pages/matkhau_email.dart';
import '../../features/auth/presentation/pages/matkhau_sdt.dart';
import '../../features/auth/presentation/pages/quen_matkhau_email.dart';
import '../../features/auth/presentation/pages/quen_matkhau_moi.dart';
import '../../features/auth/presentation/pages/quen_matkhau_otp.dart';
import '../../features/auth/presentation/pages/quen_matkhau_sdt.dart';
import '../../features/auth/presentation/pages/them_anh_daidien.dart';
import '../../features/auth/presentation/pages/trang_bat_dau.dart';
import '../../features/home/presentation/pages/global_user_search_page.dart';
import '../../features/home/presentation/pages/trang_chu.dart';
import '../../features/map/presentation/pages/map.dart';
import '../../features/messages/presentation/pages/trang_doan_chat.dart';
import '../../features/messages/presentation/pages/trang_tinnhan.dart';
import '../../features/messages/presentation/pages/trang_tinnhan_cho.dart';
import '../../features/moments/data/model/khoanh_khac_mau.dart';
import '../../features/moments/presentation/pages/trang_chia_se_camera.dart';
import '../../features/moments/presentation/pages/trang_gallery_khoanhkhac.dart';
import '../../features/moments/presentation/pages/trang_hinh_anh_chi_tiet.dart';
import '../../features/moments/presentation/pages/trang_preview_hinh.dart';
import '../../features/moments/presentation/pages/trang_vi_tri.dart';
import '../../features/notifications/presentation/pages/trang_thongbao.dart';
import '../../features/onboarding/presentation/pages/cau_hoi.dart';
import '../../features/onboarding/presentation/pages/cau_hoi_1.dart';
import '../../features/onboarding/presentation/pages/cau_hoi_2.dart';
import '../../features/onboarding/presentation/pages/cau_hoi_3.dart';
import '../../features/places/presentation/pages/trang_ban_do_dia_diem_page.dart';
import '../../features/places/presentation/pages/trang_chi_tiet_dia_diem.dart';
import '../../features/places/presentation/pages/trang_danh_gia_dia_diem.dart';
import '../../features/places/presentation/pages/trang_dia_diem.dart';
import '../../features/profile/presentation/pages/trang_caidat_hoatdong.dart';
import '../../features/profile/presentation/pages/trang_canhan.dart';
import '../../features/profile/presentation/pages/trang_chinhsua_hoso.dart';
import '../../features/profile/presentation/pages/trang_danhsach_ketnoi.dart';
import '../../features/users/presentation/pages/trang_danhsach_dachan.dart';
import '../../features/profile/presentation/pages/trang_kho_luu_tru.dart';
import '../../features/profile/presentation/pages/trang_xem_baiviet_luutru.dart';
import '../../features/social/data/models/post_model.dart';
import '../../features/social/presentation/pages/trang_binhluan.dart';
import '../../features/social/presentation/pages/trang_tao_baiviet.dart';
import '../../features/itinerary/presentation/pages/trang_ban_do_vi_tri_nhom.dart';
import '../../features/itinerary/presentation/pages/trang_chi_tiet_lich_trinh_nhom.dart';
import '../../features/itinerary/presentation/pages/trang_lich_trinh.dart';
import '../../features/itinerary/presentation/pages/trang_lich_trinh_nhom.dart';
import '../../features/itinerary/presentation/pages/trang_them_sua_lich_trinh.dart';
import '../../features/itinerary/presentation/pages/trang_them_sua_lich_trinh_nhom.dart';
import 'app_routes.dart';

class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.start: (_) => const TrangBatDauPage(),
      AppRoutes.loginEmail: (_) => const DangNhapEmailPage(),
      AppRoutes.loginPhone: (_) => const DangNhapSdtPage(),
      AppRoutes.passwordEmail: (_) => const MatKhauEmailPage(),
      AppRoutes.passwordPhone: (_) => const MatKhauSdtPage(),
      AppRoutes.registerEmail: (_) => const DangKiEmailPage(),
      AppRoutes.registerPasswordEmail: (_) => const DangKiMatKhauEmailPage(),
      AppRoutes.registerNameEmail: (_) => const DangKiTenEmailPage(),
      AppRoutes.registerPhone: (_) => const DangKiSdtPage(),
      AppRoutes.registerPasswordPhone: (_) => const DangKiMatKhauSdtPage(),
      AppRoutes.registerNamePhone: (_) => const DangKiTenSdtPage(),
      AppRoutes.addAvatar: (_) => const ThemAnhDaiDienPage(),
      AppRoutes.loading: (_) => const ManHinhChoPage(),
      AppRoutes.quenMatKhauEmail: (_) => const QuenMatKhauEmail(),
      AppRoutes.quenMatKhauSdt: (_) => const QuenMatKhauSdt(),
      AppRoutes.quenMatKhauOtp: (context) {
        final duLieu =
            ModalRoute.of(context)!.settings.arguments as DuLieuQuenMatKhau;
        return QuenMatKhauOtp(duLieu: duLieu);
      },
      AppRoutes.quenMatKhauMoi: (context) {
        final duLieu =
            ModalRoute.of(context)!.settings.arguments as DuLieuQuenMatKhau;
        return QuenMatKhauMoi(duLieu: duLieu);
      },
      AppRoutes.surveyIntro: (_) => const CauHoiPage(),
      AppRoutes.surveyQuestion1: (_) => const CauHoi1Page(),
      AppRoutes.surveyQuestion2: (_) => const CauHoi2Page(),
      AppRoutes.surveyQuestion3: (_) => const CauHoi3Page(),
      AppRoutes.home: (_) => const TrangChuPage(),
      AppRoutes.map: (_) => const MapPage(),
      AppRoutes.momentCamera: (_) => const TrangChiaSeCamera(),
      AppRoutes.trangPreviewHinh: (context) {
        final duongDanAnh =
            ModalRoute.of(context)?.settings.arguments as String?;
        return TrangPreviewHinh(duongDanAnh: duongDanAnh);
      },
      AppRoutes.trangGalleryKhoanhKhac: (_) => const TrangGalleryKhoanhKhac(),
      AppRoutes.trangViTri: (context) => const TrangViTri(),
      AppRoutes.trangHinhAnhChiTiet: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return TrangHinhAnhChiTiet(
          danhSachMoments:
              args?['danhSachMoments'] as List<KhoanhKhacMau>? ?? [],
          indexBatDau: args?['indexBatDau'] as int? ?? 0,
        );
      },
      AppRoutes.notifications: (_) => const TrangThongBaoPage(),
      AppRoutes.messages: (_) => const TrangTinNhanPage(),

      // NOTE SỬA: Cập nhật route profile để nhận tham số userId (từ arguments)
      AppRoutes.profile: (context) {
        final userId = ModalRoute.of(context)?.settings.arguments as String?;
        return TrangCaNhanPage(userId: userId);
      },
      AppRoutes.profileConnections: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return TrangDanhSachKetNoi(
          targetUserId: args?['targetUserId'] as String? ?? '',
          type: args?['type'] as String? ?? 'followers',
        );
      },
      AppRoutes.createPost: (_) => const TrangTaoBaiViet(),
      AppRoutes.postDetail: (_) =>
          const ComingSoonPage(title: 'Chi tiết bài viết'),

      AppRoutes.search: (_) => const ComingSoonPage(title: 'Tìm kiếm'),

      AppRoutes.globalUserSearch: (_) => const GlobalUserSearchPage(),

      AppRoutes.placeList: (_) => const TrangDiaDiemPage(),
      AppRoutes.placeDetail: (_) => const TrangChiTietDiaDiemPage(),
      AppRoutes.placeReview: (_) => const TrangDanhGiaDiaDiemPage(),

      AppRoutes.placeMap: (_) => const TrangBanDoDiaDiemPage(),
      AppRoutes.tripList: (_) => const TrangLichTrinhPage(),
      AppRoutes.tripCreate: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return TrangThemSuaLichTrinhPage(
          itineraryId: args?['itineraryId'] as int?,
          initialPlaceId: args?['initialPlaceId'] as int?,
        );
      },
      AppRoutes.tripDetail: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return TrangThemSuaLichTrinhPage(
          itineraryId: args?['itineraryId'] as int?,
        );
      },
      AppRoutes.groupTripList: (_) => const TrangLichTrinhNhomPage(),
      AppRoutes.groupTripCreate: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return TrangThemSuaLichTrinhNhomPage(tripId: args?['tripId'] as int?);
      },
      AppRoutes.groupTripDetail: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return TrangChiTietLichTrinhNhomPage(
          tripId: args?['tripId'] as int? ?? 0,
        );
      },
      AppRoutes.groupTripMap: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        return TrangBanDoViTriNhomPage(
          tripId: args?['tripId'] as int? ?? 0,
          focusUserId: args?['focusUserId'] as String?,
        );
      },
      AppRoutes.editProfile: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return TrangChinhSuaHoSoPage(
          initialProfile: args is MyProfile ? args : null,
        );
      },
      AppRoutes.settings: (_) => const TrangCaiDatHoatDongPage(),
      AppRoutes.archive: (_) => const TrangKhoLuuTruPage(),
      AppRoutes.archivePostDetail: (context) {
        final post = ModalRoute.of(context)?.settings.arguments as PostModel?;
        if (post == null) {
          return const ComingSoonPage(
            title: 'Không tìm thấy bài viết',
            description: 'Bài viết đã lưu trữ không hợp lệ.',
          );
        }

        return TrangXemBaiVietLuuTruPage(post: post);
      },
      AppRoutes.followRequests: (_) =>
          const ComingSoonPage(title: 'Yêu cầu theo dõi'),
      AppRoutes.friendSuggestions: (_) =>
          const ComingSoonPage(title: 'Gợi ý bạn bè'),
      AppRoutes.adminDashboard: (_) =>
          const ComingSoonPage(title: 'Quản trị viên'),
      AppRoutes.adminReports: (_) =>
          const ComingSoonPage(title: 'Báo cáo vi phạm'),
      AppRoutes.trangBinhLuan: (context) {
        final postId = ModalRoute.of(context)?.settings.arguments as int? ?? 1;
        return TrangBinhLuan(postId: postId);
      },
      AppRoutes.blockedUsers: (_) => const TrangDanhSachDaChanPage(),
      AppRoutes.waitingMessages: (_) => const TrangTinNhanChoPage(),
      AppRoutes.loginCallback: (_) => const GoogleLoginCallbackPage(),
      AppRoutes.chatDetail: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final name = args?['name'] as String? ?? 'Người dùng';
        final isWaiting = args?['isWaiting'] as bool? ?? false;
        return TrangDoanChatPage(
          name: name,
          isWaiting: isWaiting,
          conversationId: args?['conversationId'] as int?,
          otherProfileId: args?['otherProfileId'] as String?,
          avatarUrl: args?['avatarUrl'] as String?,
        );
      },
    };
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => ComingSoonPage(
        title: 'Không tìm thấy màn hình',
        description: 'Route "${settings.name}" chưa được khai báo.',
      ),
    );
  }
}
