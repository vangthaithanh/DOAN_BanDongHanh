import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/profile_service.dart';

/// NOTE SỬA:
/// Màn chỉnh sửa hồ sơ thật.
/// Responsive theo kích thước điện thoại:
/// - Dùng LayoutBuilder.
/// - Dùng SingleChildScrollView.
/// - Không fix cứng chiều cao.
/// - Khi bàn phím mở vẫn kéo được.
class TrangChinhSuaHoSoPage extends StatefulWidget {
  final MyProfile? initialProfile;

  const TrangChinhSuaHoSoPage({super.key, this.initialProfile});

  @override
  State<TrangChinhSuaHoSoPage> createState() => _TrangChinhSuaHoSoPageState();
}

class _TrangChinhSuaHoSoPageState extends State<TrangChinhSuaHoSoPage> {
  final _formKey = GlobalKey<FormState>();

  final _profileService = ProfileService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  final _nicknameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _facebookController = TextEditingController();

  MyProfile? _profile;
  File? _avatarFile;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _profile = widget.initialProfile;
    _fillForm();
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    if (_profile != null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final data = await _profileService.loadMine();

      _profile = data.profile;
      _fillForm();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _fillForm() {
    final profile = _profile;

    if (profile == null) {
      return;
    }

    _nicknameController.text = profile.nickname;
    _fullNameController.text = profile.fullName;
    _bioController.text = profile.bio;
    _facebookController.text = profile.facebookUrl;
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 900,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _avatarFile = File(picked.path);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      /// NOTE SỬA:
      /// Avatar upload qua AuthService để đúng Storage RLS:
      /// <user_id>/avatar_xxx.jpg
      if (_avatarFile != null) {
        await _authService.uploadAvatar(_avatarFile!);
      }

      /// NOTE SỬA:
      /// Text profile lưu vào bảng profiles.
      await _profileService.updateProfile(
        nickname: _nicknameController.text,
        fullName: _fullNameController.text,
        bio: _bioController.text,
        facebookUrl: _facebookController.text,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Đã lưu hồ sơ');
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(_friendlyError(e));
    }

    if (mounted) {
      setState(() {
        _saving = false;
      });
    }
  }

  String _friendlyError(Object e) {
    final message = e.toString();

    if (message.contains('row-level security')) {
      return 'RLS chưa cho phép sửa hồ sơ.';
    }

    if (message.contains('Biệt danh đã tồn tại')) {
      return 'Biệt danh đã tồn tại';
    }

    if (message.contains('không có quyền')) {
      return message.replaceFirst('Exception: ', '');
    }

    return message.replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _facebookController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isSmallPhone = width < 360;

                  final horizontalPadding = isSmallPhone ? 16.0 : 22.0;
                  final avatarRadius = isSmallPhone ? 46.0 : 54.0;
                  final buttonHeight = isSmallPhone ? 46.0 : 50.0;

                  ImageProvider? avatarProvider;

                  if (_avatarFile != null) {
                    avatarProvider = FileImage(_avatarFile!);
                  } else if (_profile?.avatarUrl.isNotEmpty == true) {
                    avatarProvider = NetworkImage(_profile!.avatarUrl);
                  }

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      24 + viewInsets.bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 520,
                          minHeight: constraints.maxHeight - 24,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: GestureDetector(
                                  onTap: _saving ? null : _pickAvatar,
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: avatarRadius,
                                        backgroundColor: const Color(
                                          0xFF4AA8FF,
                                        ),
                                        backgroundImage: avatarProvider,
                                        child: avatarProvider == null
                                            ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 52,
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              _input(
                                controller: _nicknameController,
                                label: 'Biệt danh',
                                enabled: !_saving,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nhập biệt danh';
                                  }

                                  if (value.trim().length < 3) {
                                    return 'Biệt danh tối thiểu 3 ký tự';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _input(
                                controller: _fullNameController,
                                label: 'Tên hiển thị',
                                enabled: !_saving,
                              ),
                              const SizedBox(height: 14),
                              _input(
                                controller: _bioController,
                                label: 'Tiểu sử',
                                enabled: !_saving,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 14),
                              _input(
                                controller: _facebookController,
                                label: 'Link Facebook',
                                enabled: !_saving,
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                height: buttonHeight,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4AA8FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Lưu thay đổi',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
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

  Widget _input({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF4AA8FF),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4AA8FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
