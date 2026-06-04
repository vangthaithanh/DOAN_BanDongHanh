import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/dia_diem_model.dart';
import '../../data/services/dia_diem_service.dart';
import '../widgets/place_common_widgets.dart';

class TrangDanhGiaDiaDiemPage extends StatefulWidget {
  const TrangDanhGiaDiaDiemPage({super.key});

  @override
  State<TrangDanhGiaDiaDiemPage> createState() =>
      _TrangDanhGiaDiaDiemPageState();
}

class _TrangDanhGiaDiaDiemPageState extends State<TrangDanhGiaDiaDiemPage> {
  final TextEditingController _noiDungController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final DiaDiemService _service = DiaDiemService();

  DiaDiemModel? _diaDiem;
  List<DanhGiaDiaDiemModel> _danhGiaGanDay = [];

  // NOTE SỬA:
  // Nếu user đã đánh giá rồi thì màn này tự đổ sao + nội dung cũ vào form.
  // Khi lưu lại sẽ cập nhật đánh giá cũ chứ không tạo thêm đánh giá mới.
  DanhGiaDiaDiemModel? _danhGiaCuaToi;

  int _soSao = 0;
  bool _dangTai = true;
  bool _dangLuu = false;
  String? _loi;
  final List<XFile> _hinhAnhDaChon = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_diaDiem == null && _dangTai) {
      final id = ModalRoute.of(context)?.settings.arguments as int?;
      _taiDuLieu(id);
    }
  }

  @override
  void dispose() {
    _noiDungController.dispose();
    super.dispose();
  }

  Future<void> _taiDuLieu(int? id) async {
    if (id == null) {
      setState(() {
        _dangTai = false;
        _loi = 'Không nhận được mã địa điểm.';
      });
      return;
    }

    try {
      final diaDiem = await _service.layDiaDiemTheoId(id);
      final reviews = await _service.layDanhGiaTheoDiaDiem(id, limit: 10);
      final myReview = await _service.layDanhGiaCuaToi(id);

      if (!mounted) return;

      if (diaDiem == null) {
        setState(() {
          _dangTai = false;
          _loi = 'Không tìm thấy địa điểm này.';
        });
        return;
      }

      final reviewsWithoutMine = myReview == null
          ? reviews
          : reviews
                .where((item) => item.maDanhGia != myReview.maDanhGia)
                .toList();

      if (myReview != null) {
        _soSao = myReview.soSao;
        _noiDungController.text = myReview.noiDungHienThi;
      }

      setState(() {
        _diaDiem = diaDiem;
        _danhGiaGanDay = reviewsWithoutMine.take(5).toList();
        _danhGiaCuaToi = myReview;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e.toString().replaceFirst('Exception: ', '');
        _dangTai = false;
      });
    }
  }

  Future<void> _chonAnhTuThuVien() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return;

      setState(() {
        _hinhAnhDaChon.addAll(images);
      });
    } catch (e) {
      _showMessage('Không chọn được ảnh. Bạn kiểm tra quyền truy cập ảnh nha.');
    }
  }

  Future<void> _chupAnh() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _hinhAnhDaChon.add(image);
      });
    } catch (e) {
      _showMessage('Không mở được camera. Bạn kiểm tra quyền camera nha.');
    }
  }

  Future<void> _luuDanhGia(DiaDiemModel diaDiem) async {
    if (_dangLuu) return;

    final noiDung = _noiDungController.text.trim();

    if (_soSao == 0) {
      _showMessage('Bạn chọn số sao trước nha');
      return;
    }

    if (noiDung.isEmpty) {
      _showMessage('Bạn nhập nội dung đánh giá trước nha');
      return;
    }

    setState(() {
      _dangLuu = true;
    });

    try {
      await _service.taoHoacCapNhatDanhGia(
        maDiaDiem: diaDiem.maDiaDiem,
        soSao: _soSao,
        noiDung: noiDung,
        hinhAnh: List<XFile>.from(_hinhAnhDaChon),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _dangLuu = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (width * 0.05).clamp(16.0, 28.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _dangTai
            ? const Center(child: CircularProgressIndicator())
            : _loi != null
            ? _errorView()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        22,
                        horizontalPadding,
                        24,
                      ),
                      children: [
                        _header(),
                        const SizedBox(height: 22),
                        _placeSummary(_diaDiem!),
                        const SizedBox(height: 18),
                        _starPicker(),
                        const SizedBox(height: 14),
                        _reviewInput(),
                        const SizedBox(height: 16),
                        _mediaButtons(),
                        const SizedBox(height: 10),
                        _oldImagesInfo(),
                        const SizedBox(height: 10),
                        _pickedImagesPreview(),
                        const SizedBox(height: 18),
                        _recentReviews(),
                      ],
                    ),
                  ),
                  _bottomSaveButton(_diaDiem!),
                ],
              ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white70,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              _loi ?? 'Lỗi không xác định',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            BluePillButton(
              text: 'Quay lại',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final isEdit = _danhGiaCuaToi != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackCircleButton(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Chỉnh sửa đánh giá' : 'Đánh giá',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEdit
                    ? 'Bạn đang cập nhật đánh giá đã gửi trước đó'
                    : 'Mọi người có thể nhìn thấy đánh giá của bạn',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeSummary(DiaDiemModel diaDiem) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          PlaceImage(
            path: diaDiem.hinhAnh.first,
            width: 72,
            height: 72,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diaDiem.tenDiaDiem,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                PlaceInfoLine(
                  icon: Icons.location_on_outlined,
                  text: diaDiem.diaChiHienThi,
                  maxLines: 2,
                ),
                RatingText(rating: diaDiem.diemTrungBinh),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _starPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn chấm địa điểm này mấy sao?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            final selected = value <= _soSao;

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _soSao = value;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  selected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _reviewInput() {
    return TextField(
      controller: _noiDungController,
      minLines: 6,
      maxLines: 8,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Nhập đánh giá...',
        hintStyle: const TextStyle(
          color: Colors.white54,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: const Color(0xFF414141),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _mediaButtons() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Thêm hình ảnh đánh giá',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _chupAnh,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.photo_camera_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _chonAnhTuThuVien,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.image_outlined, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _oldImagesInfo() {
    final oldImages = _danhGiaCuaToi?.hinhAnh ?? [];

    if (oldImages.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final itemWidth = (width * 0.28).clamp(96.0, 116.0).toDouble();
    final itemHeight = (itemWidth * 0.92).clamp(88.0, 108.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh hiện tại của đánh giá',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: itemHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: oldImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return PlaceImage(
                path: oldImages[index],
                width: itemWidth,
                height: itemHeight,
                borderRadius: BorderRadius.circular(10),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lưu ý: khi bấm cập nhật, ảnh hiện tại sẽ được thay bằng ảnh mới bạn chọn. Nếu không chọn ảnh mới thì đánh giá sẽ không còn ảnh.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _pickedImagesPreview() {
    if (_hinhAnhDaChon.isEmpty) {
      return Container(
        height: 92,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF202020),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Chưa chọn ảnh mới. Bạn có thể lưu đánh giá không cần ảnh.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final itemWidth = (width * 0.31).clamp(104.0, 128.0).toDouble();
    final itemHeight = (itemWidth * 1.04).clamp(108.0, 132.0).toDouble();

    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _hinhAnhDaChon.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              PlaceImage(
                path: _hinhAnhDaChon[index].path,
                width: itemWidth,
                height: itemHeight,
                borderRadius: BorderRadius.circular(10),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () {
                    setState(() {
                      _hinhAnhDaChon.removeAt(index);
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _recentReviews() {
    if (_danhGiaGanDay.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Một số đánh giá trước đó',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        ..._danhGiaGanDay.map(
          (item) => ReviewTile(review: item, showImages: true),
        ),
      ],
    );
  }

  Widget _bottomSaveButton(DiaDiemModel diaDiem) {
    final isEdit = _danhGiaCuaToi != null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _dangLuu ? null : () => _luuDanhGia(diaDiem),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF3A3A3A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: _dangLuu
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isEdit ? 'Cập nhật đánh giá' : 'Lưu đánh giá',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
