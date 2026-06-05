import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart'; // Thư viện mới để lưu ảnh
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/navigation/app_bottom_nav.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../../messages/data/message_service.dart';
import '../../data/khoanh_khac_service.dart';
import '../../data/model/khoanh_khac_mau.dart';
import '../widgets/menu_nguoi_xem.dart';
import '../widgets/thanh_tren_khoanhkhac.dart';

class TrangHinhAnhChiTiet extends StatefulWidget {
  final List<KhoanhKhacMau> danhSachMoments;
  final int indexBatDau;

  const TrangHinhAnhChiTiet({
    super.key,
    required this.danhSachMoments,
    required this.indexBatDau,
  });

  @override
  State<TrangHinhAnhChiTiet> createState() => _TrangHinhAnhChiTietState();
}

class _TrangHinhAnhChiTietState extends State<TrangHinhAnhChiTiet> {
  late PageController _pageController;
  late int _currentIndex;
  late List<KhoanhKhacMau> _hienThiMoments;

  final TextEditingController _tinNhanController = TextEditingController();
  final KhoanhKhacService _service = KhoanhKhacService();
  final MessageService _messageService = MessageService();
  Timer? _timer;

  List<Map<String, dynamic>> _danhSachProfiles = [];
  Map<String, dynamic>? _selectedProfile;
  bool _hienMenuNguoiXem = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.indexBatDau;
    _hienThiMoments = widget.danhSachMoments;
    _pageController = PageController(initialPage: widget.indexBatDau);
    _loadProfiles();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _tinNhanController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final results = await Future.wait([
        _service.getMyProfile(),
        _service.getBanBe(),
      ]);
      final me = results[0] as Map<String, dynamic>?;
      final friends = results[1] as List<Map<String, dynamic>>;
      if (!mounted) return;
      setState(() {
        _danhSachProfiles = [
          if (me != null) {...me, 'nickname': 'Bạn'},
          ...friends,
        ];
      });
    } catch (e) {
      debugPrint("Lỗi tải profiles: $e");
    }
  }

  void _doiTrangThaiMenu() =>
      setState(() => _hienMenuNguoiXem = !_hienMenuNguoiXem);
  void _tatMenu() => setState(() => _hienMenuNguoiXem = false);

  void _onProfileSelected(Map<String, dynamic>? profile) async {
    setState(() {
      _selectedProfile = profile;
      _hienMenuNguoiXem = false;
    });

    try {
      final newList = await _service.getKhoanhKhac(
        profileId: profile?['id']?.toString(),
      );
      setState(() {
        _hienThiMoments = newList;
        _currentIndex = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    } catch (e) {
      debugPrint("Lỗi lọc moments: $e");
    }
  }

  Future<void> _guiTinNhan() async {
    if (_hienThiMoments.isEmpty) return;
    final noiDung = _tinNhanController.text.trim();
    if (noiDung.isEmpty) return;

    final moment = _hienThiMoments[_currentIndex];
    final ownerProfileId = moment.profileId ?? '';
    if (ownerProfileId.isEmpty || ownerProfileId == _currentUserId) return;

    _tinNhanController.clear();

    try {
      final conversationId = await _messageService.sendMomentReply(
        momentOwnerProfileId: ownerProfileId,
        replyText: noiDung,
        momentId: moment.id,
        momentImageUrl: moment.duongDanAnh,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.chatDetail,
        arguments: {
          'conversationId': conversationId,
          'name': moment.tenNguoiDang,
          'isWaiting': false,
          'avatarUrl': moment.avatarUrl,
          'otherProfileId': ownerProfileId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi tin: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // 📥 HÀM TẢI ẢNH VỀ MÁY (SỬ DỤNG GAL & XỬ LÝ QUYỀN CHÍNH XÁC)
  Future<void> _taiAnh() async {
    if (_hienThiMoments.isEmpty) return;
    final duongDan = _hienThiMoments[_currentIndex].duongDanAnh;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        PermissionStatus status;

        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ (Samsung A23) cần quyền photos
          status = await Permission.photos.request();
        } else {
          // Android cũ cần storage
          status = await Permission.storage.request();
        }

        if (!status.isGranted && !status.isLimited) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Ứng dụng cần quyền truy cập ảnh để tải xuống',
              ),
              action: SnackBarAction(
                label: 'Cài đặt',
                onPressed: openAppSettings,
              ),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tải ảnh xuống...'),
          duration: Duration(milliseconds: 800),
        ),
      );

      String localPath;
      if (duongDan.startsWith('http')) {
        final tempDir = await getTemporaryDirectory();
        localPath =
            "${tempDir.path}/temp_moment_${DateTime.now().millisecondsSinceEpoch}.jpg";
        await Dio().download(duongDan, localPath);
      } else {
        localPath = duongDan.replaceFirst('file://', '');
      }

      // Lưu vào Album bằng Gal
      if (await File(localPath).exists()) {
        await Gal.putImage(localPath);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu ảnh vào Album thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("Không tìm thấy tệp ảnh");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tải ảnh thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  void _moMenuTuyChon() {
    if (_hienThiMoments.isEmpty) return;
    final momentHienTai = _hienThiMoments[_currentIndex];
    final isOwner = _currentUserId == momentHienTai.profileId;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),

              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Xóa ảnh này',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _xacNhanXoa(momentHienTai.id, momentHienTai.profileId);
                  },
                ),

              ListTile(
                leading: const Icon(Icons.close, color: Colors.white),
                title: const Text('Hủy', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _xacNhanXoa(int id, String? profileId) async {
    if (_currentUserId != profileId) return;

    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bạn có chắc muốn xóa khoảnh khắc này không?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (xacNhan == true) {
      try {
        await Supabase.instance.client.from('moments').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa ảnh thành công')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String tenHienTai = 'Bạn bè';
    if (_selectedProfile != null) {
      tenHienTai =
          _selectedProfile!['nickname'] ??
          _selectedProfile!['full_name'] ??
          'Người dùng';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const AppBottomNav(activeTab: MainTab.moments),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const ThanhTrenKhoanhKhac(),
                NutChonNguoiXem(
                  onTap: _doiTrangThaiMenu,
                  tenHienTai: tenHienTai,
                ),
                Expanded(
                  child: _hienThiMoments.isEmpty
                      ? const Center(
                          child: Text(
                            "Không có khoảnh khắc nào",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: _hienThiMoments.length,
                          onPageChanged: (index) =>
                              setState(() => _currentIndex = index),
                          itemBuilder: (context, index) {
                            final moment = _hienThiMoments[index];
                            return _buildTrangMoment(moment);
                          },
                        ),
                ),
              ],
            ),
            if (_hienMenuNguoiXem) _lopMenuNguoiXem(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrangMoment(KhoanhKhacMau moment) {
    final isMyMoment = _currentUserId == moment.profileId;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _khungAnhLon(350, moment),
                  const SizedBox(height: 20),
                  _thongTinNguoiDang(moment),

                  if (!isMyMoment) ...[
                    const SizedBox(height: 14),
                    _oGuiTinNhan(),
                  ],

                  const Spacer(),

                  const SizedBox(height: 16),
                  _thanhCongCuNoi(),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hienThiAnh(String duongDan) {
    if (duongDan.isEmpty) {
      return const Center(
        child: Text('Không có ảnh', style: TextStyle(color: Colors.white)),
      );
    }
    if (duongDan.startsWith('http')) {
      return Image.network(
        duongDan,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.white54, size: 50),
      );
    }
    final path = duongDan.replaceFirst('file://', '');
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, color: Colors.white54, size: 50),
    );
  }

  Widget _khungAnhLon(double chieuCao, KhoanhKhacMau moment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        height: chieuCao,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: const Color(0xFF1A1A1A),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: _hienThiAnh(moment.duongDanAnh)),
            Positioned(
              top: 14,
              right: 14,
              child: GestureDetector(
                onTap: _moMenuTuyChon,
                child: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.more_vert, color: Colors.white),
                ),
              ),
            ),
            _thongTinViTri(moment.viTri),
          ],
        ),
      ),
    );
  }

  Widget _thongTinNguoiDang(KhoanhKhacMau moment) {
    final thoiGianHienThi = _thoiGianRelative(moment.thoiGian);
    final avatar = moment.avatarUrl ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF4AA8FF),
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar.isEmpty
              ? const Icon(Icons.person, size: 18, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              moment.tenNguoiDang,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              thoiGianHienThi,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  String _thoiGianRelative(DateTime? tg) {
    if (tg == null) return 'Vừa xong';
    final diff = DateTime.now().difference(tg.toLocal());
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${tg.day}/${tg.month}/${tg.year}';
  }

  Widget _thongTinViTri(String? viTri) {
    final text = viTri?.trim();

    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 285),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.58),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _oGuiTinNhan() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tinNhanController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Gửi tin nhắn...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: _guiTinNhan,
              icon: const Icon(Icons.send, color: Colors.blue, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thanhCongCuNoi() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.trangGalleryKhoanhKhac,
            (r) => false,
          ),
          icon: const Icon(LucideIcons.grid2x2, color: Colors.white),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.momentCamera,
            (r) => false,
          ),
          icon: const Icon(LucideIcons.camera, color: Colors.white),
        ),
        IconButton(
          onPressed: _taiAnh,
          icon: const Icon(LucideIcons.download, color: Colors.white),
        ),
      ],
    );
  }

  Widget _lopMenuNguoiXem() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _tatMenu,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: MenuNguoiXem(
              danhSachProfiles: _danhSachProfiles,
              onProfileSelected: _onProfileSelected,
            ),
          ),
        ),
      ),
    );
  }
}
