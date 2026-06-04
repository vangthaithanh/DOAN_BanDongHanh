import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';

/// NOTE SỬA:
/// Màn thêm avatar sau đăng ký.
/// Responsive theo điện thoại.
/// Upload ảnh qua AuthService.uploadAvatar()
/// để đúng Storage RLS: <user_id>/avatar_xxx.jpg.
class ThemAnhDaiDienPage extends StatefulWidget {
  const ThemAnhDaiDienPage({super.key});

  @override
  State<ThemAnhDaiDienPage> createState() => _ThemAnhDaiDienPageState();
}

class _ThemAnhDaiDienPageState extends State<ThemAnhDaiDienPage> {
  final AuthService authService = AuthService();
  final ImagePicker picker = ImagePicker();

  File? selectedImage;
  bool isLoading = false;

  Future<void> pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 900,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedImage = File(picked.path);
    });
  }

  Future<void> continueNext() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (selectedImage != null) {
        await authService.uploadAvatar(selectedImage!);
      }

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.surveyIntro,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF4AA8FF);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isSmallPhone = width < 360;

            final horizontalPadding = isSmallPhone ? 20.0 : 24.0;
            final titleSize = isSmallPhone ? 25.0 : 28.0;
            final avatarSize = (constraints.maxWidth * 0.35).clamp(
              110.0,
              150.0,
            );
            final topGap = isSmallPhone ? 34.0 : 56.0;
            final buttonHeight = isSmallPhone ? 50.0 : 54.0;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _backButton(context),
                        SizedBox(height: topGap),
                        Text(
                          'Thêm ảnh đại diện',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Ảnh đại diện giúp bạn bè nhận ra bạn dễ hơn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                        const SizedBox(height: 34),
                        Center(
                          child: GestureDetector(
                            onTap: isLoading ? null : pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: avatarSize,
                                  height: avatarSize,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E2E31),
                                    shape: BoxShape.circle,
                                    image: selectedImage != null
                                        ? DecorationImage(
                                            image: FileImage(selectedImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: selectedImage == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 60,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallPhone ? 90 : 130),
                        SizedBox(
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : continueNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    selectedImage == null
                                        ? 'Bỏ qua'
                                        : 'Tiếp tục',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: isLoading ? null : () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFF2E2E31),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
