import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/mock/mock_dia_diem.dart';
import '../../data/models/dia_diem_model.dart';
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

  int _soSao = 0;
  final List<String> _hinhAnhDaChon = [];

  @override
  void dispose() {
    _noiDungController.dispose();
    super.dispose();
  }

  Future<void> _chonAnhTuThuVien() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);

    if (images.isEmpty) return;

    setState(() {
      _hinhAnhDaChon.addAll(images.map((item) => item.path));
    });
  }

  Future<void> _chupAnh() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _hinhAnhDaChon.add(image.path);
    });
  }

  void _luuDanhGia(DiaDiemModel diaDiem) {
    final noiDung = _noiDungController.text.trim();

    if (_soSao == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chọn số sao trước nha')),
      );
      return;
    }

    if (noiDung.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn nhập nội dung đánh giá trước nha')),
      );
      return;
    }

    // Hiện tại lưu mock trong RAM.
    // Sau này nối API:
    // 1. Upload ảnh lên Cloudinary/Firebase.
    // 2. Lấy URL ảnh.
    // 3. Gửi maDiaDiem, soSao, noiDung, mediaUrls lên backend.
    KhoDanhGiaDiaDiem.instance.themDanhGia(
      maDiaDiem: diaDiem.maDiaDiem,
      soSao: _soSao,
      noiDung: noiDung,
      hinhAnh: List<String>.from(_hinhAnhDaChon),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as int?;
    final diaDiem = timDiaDiemTheoId(id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                children: [
                  _header(),
                  const SizedBox(height: 34),
                  Text(
                    diaDiem.tenDiaDiem,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _starPicker(),
                  const SizedBox(height: 14),
                  _reviewInput(),
                  const SizedBox(height: 16),
                  _mediaButtons(),
                  const SizedBox(height: 18),
                  _pickedImagesPreview(diaDiem),
                ],
              ),
            ),
            _bottomSaveButton(diaDiem),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BackCircleButton(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Đánh giá',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Mọi người có thể nhìn thấy đánh giá của bạn',
                style: TextStyle(
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

  Widget _starPicker() {
    return Row(
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
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
        );
      }),
    );
  }

  Widget _reviewInput() {
    return TextField(
      controller: _noiDungController,
      minLines: 6,
      maxLines: 6,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Nhập đánh giá......',
        hintStyle: const TextStyle(
          color: Colors.white54,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: const Color(0xFF414141),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _mediaButtons() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _chupAnh,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.photo_camera_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 18),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _chonAnhTuThuVien,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.image_outlined, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _pickedImagesPreview(DiaDiemModel diaDiem) {
    final previewImages = _hinhAnhDaChon.isEmpty
        ? diaDiem.hinhAnh
        : _hinhAnhDaChon;

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: previewImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 3),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              PlaceImage(
                path: previewImages[index],
                width: 126,
                height: 140,
                borderRadius: BorderRadius.circular(8),
              ),
              if (_hinhAnhDaChon.isNotEmpty)
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

  Widget _bottomSaveButton(DiaDiemModel diaDiem) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: () => _luuDanhGia(diaDiem),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Lưu đánh giá',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
