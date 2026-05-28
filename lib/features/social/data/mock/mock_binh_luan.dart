import '../models/binh_luan_model.dart';

const List<BinhLuanModel> danhSachBinhLuanMock = [
  BinhLuanModel(
    id: 1,
    postId: 1,
    tenNguoiBinhLuan: 'BongAnhHung',
    thoiGian: '3 ngày',
    noiDung: 'Nơi này rất tuyệt',
    danhSachTraLoi: [
      BinhLuanModel(
        id: 2,
        postId: 1,
        tenNguoiBinhLuan: 'BongAnhHung',
        tenNguoiDuocTraLoi: 'BongAnhHung',
        thoiGian: '3 ngày',
        noiDung: 'Nơi này rất tuyệt',
      ),
    ],
  ),
];

List<BinhLuanModel> layBinhLuanTheoBaiViet(int postId) {
  return danhSachBinhLuanMock
      .where((binhLuan) => binhLuan.postId == postId)
      .toList();
}