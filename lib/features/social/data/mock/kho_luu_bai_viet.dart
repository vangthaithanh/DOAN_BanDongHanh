import 'package:flutter/material.dart';

import '../models/post_model.dart';

/// Kho lưu bài viết toàn cục — dùng ChangeNotifier để trang chủ
/// và trang cá nhân tự cập nhật khi có bài viết mới.
class KhoLuuBaiViet extends ChangeNotifier {
  KhoLuuBaiViet._();

  static final KhoLuuBaiViet instance = KhoLuuBaiViet._();

  final List<PostModel> _danhSach = [];

  /// Tất cả bài viết (mới nhất trước)
  List<PostModel> get danhSach => List.unmodifiable(_danhSach);

  /// Chỉ bài viết của mình
  List<PostModel> get danhSachCuaToi =>
      _danhSach.where((p) => p.laBaiVietCuaToi).toList();

  void themBaiViet({
    required String? duongDanAnh,
    required String? caption,
    required String? viTri,
    required List<String> danhSachHashTag,
    required List<String> danhSachBanBe,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch;

    final baiVietMoi = PostModel(
      id: id,
      tenNguoiDang: 'Xuthu',
      thoiGian: 'Vừa xong',
      caption: caption?.isNotEmpty == true ? caption : null,
      danhSachAnh: duongDanAnh != null ? [duongDanAnh] : [],
      viTri: viTri,
      danhSachHashTag: danhSachHashTag,
      danhSachBanBeDuocTag: danhSachBanBe,
      soLuotThich: 0,
      soLuotBinhLuan: 0,
      laBaiVietCuaToi: true,
    );

    _danhSach.insert(0, baiVietMoi);
    notifyListeners();
  }

  void toggleThich(int id) {
    final idx = _danhSach.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final p = _danhSach[idx];
    _danhSach[idx] = p.copyWith(
      soLuotThich: p.soLuotThich > 0 ? p.soLuotThich - 1 : p.soLuotThich + 1,
    );
    notifyListeners();
  }
}