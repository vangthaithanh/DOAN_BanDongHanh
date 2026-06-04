import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/auth_service.dart';

/// NOTE SỬA:
/// Màn hình chờ không còn tự nhảy cứng vào '/trang-chu'.
///
/// Sau khi loading 100%, màn này gọi AuthService.getNextRouteAfterAuth():
/// - Chưa đăng nhập        -> trang bắt đầu
/// - Chưa có avatar        -> thêm ảnh đại diện
/// - Chưa trả lời câu hỏi  -> khảo sát
/// - Đủ dữ liệu            -> trang chủ
class ManHinhChoPage extends StatefulWidget {
  const ManHinhChoPage({super.key});

  @override
  State<ManHinhChoPage> createState() => _ManHinhChoPageState();
}

class _ManHinhChoPageState extends State<ManHinhChoPage> {
  final AuthService authService = AuthService();

  int progress = 0;
  Timer? timer;
  bool isCheckingRoute = false;

  @override
  void initState() {
    super.initState();
    startLoading();
  }

  void startLoading() {
    timer = Timer.periodic(const Duration(milliseconds: 35), (timer) async {
      if (!mounted) return;

      if (progress < 100) {
        setState(() {
          progress++;
        });
      } else {
        timer.cancel();

        if (isCheckingRoute) return;

        setState(() {
          isCheckingRoute = true;
        });

        await goNextByAuthState();
      }
    });
  }

  Future<void> goNextByAuthState() async {
    try {
      /// NOTE SỬA:
      /// Đây là chỗ quan trọng nhất.
      /// Không đi thẳng vào trang chủ nữa.
      final nextRoute = await authService.getNextRouteAfterAuth();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );

      setState(() {
        isCheckingRoute = false;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF4AA8FF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallPhone = constraints.maxWidth < 360;
            final logoSize = isSmallPhone ? 68.0 : 76.0;
            final titleSize = isSmallPhone ? 30.0 : 34.0;

            return Column(
              children: [
                const Spacer(flex: 3),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Go',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: 'Mate',
                            style: TextStyle(
                              color: blue,
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCheckingRoute) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Đang kiểm tra tài khoản...',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ],
                ),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 18,
                          width: double.infinity,
                          color: Colors.white24,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 18,
                            width: constraints.maxWidth * (progress / 100),
                            color: blue,
                          ),
                        ),
                        Text(
                          '$progress%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
