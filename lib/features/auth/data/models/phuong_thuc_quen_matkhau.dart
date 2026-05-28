enum PhuongThucQuenMatKhau {
  email,
  sdt,
}

extension PhuongThucQuenMatKhauMoRong on PhuongThucQuenMatKhau {
  String get tenHienThi {
    switch (this) {
      case PhuongThucQuenMatKhau.email:
        return 'Email';
      case PhuongThucQuenMatKhau.sdt:
        return 'Số điện thoại';
    }
  }

  String get tenNgan {
    switch (this) {
      case PhuongThucQuenMatKhau.email:
        return 'email';
      case PhuongThucQuenMatKhau.sdt:
        return 'số điện thoại';
    }
  }
}