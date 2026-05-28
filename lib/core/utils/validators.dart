class Validators {
  const Validators._();

  static bool isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
  }

  static bool isValidVietnamPhone(String value) {
    final phone = value.trim();
    return RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$').hasMatch(phone);
  }

  static bool isValidPassword(String value) {
    return value.length >= 6;
  }

  static bool isValidNickname(String value) {
    final nickname = value.trim();
    return nickname.length >= 3 && nickname.length <= 50;
  }
}
