import 'dart:io';

import 'package:do_an/app/routes/app_routes.dart';
import 'package:do_an/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ThemAnhDaiDienPage extends StatefulWidget {
  const ThemAnhDaiDienPage({super.key});

  @override
  State<ThemAnhDaiDienPage> createState() => _ThemAnhDaiDienPageState();
}

class _ThemAnhDaiDienPageState extends State<ThemAnhDaiDienPage> {
  static const Color blue = Color(0xFF4AA8FF);

  final ImagePicker picker = ImagePicker();
  final AuthService authService = AuthService();

  File? selectedImage;
  bool isLoading = false;

  Future<void> pickAvatar() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<void> handleContinue() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (selectedImage != null) {
        await authService.uploadAvatar(selectedImage!);
      }

      if (!mounted) return;

      Navigator.pushNamed(context, AppRoutes.surveyIntro);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void handleSkip() {
    Navigator.pushNamed(context, AppRoutes.surveyIntro);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final nickname = args?['nickname'] as String? ?? 'bạn';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: isLoading ? null : handleSkip,
                  child: const Text(
                    'Bỏ qua >',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Transform.translate(
                offset: const Offset(0, -22),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Xin chào, “$nickname”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: isLoading ? null : pickAvatar,
                child: selectedImage == null
                    ? Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 46,
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: isLoading ? null : pickAvatar,
                child: const Text(
                  'Thêm ảnh đại diện',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    disabledBackgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    isLoading ? 'Đang lưu...' : 'Tiếp tục →',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
