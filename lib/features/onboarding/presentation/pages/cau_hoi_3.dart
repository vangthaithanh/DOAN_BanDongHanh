import 'package:do_an/app/routes/app_routes.dart';
import 'package:do_an/core/services/auth_service.dart';
import 'package:do_an/features/onboarding/data/onboarding_state.dart';
import 'package:flutter/material.dart';

import 'cau_hoi_1.dart';

class CauHoi3Page extends StatefulWidget {
  const CauHoi3Page({super.key});

  @override
  State<CauHoi3Page> createState() => _CauHoi3PageState();
}

class _CauHoi3PageState extends State<CauHoi3Page> {
  final AuthService authService = AuthService();

  final Set<int> selectedIndexes = {};

  bool isLoading = false;

  final List<String> options = [
    'Gần tôi',
    'Local',
    'Đang Hot',
    'Dễ đi trong ngày',
    'Có bài review đi kèm',
    'Khác',
  ];

  final List<String?> optionCodes = [
    'GAN_TOI',
    'LOCAL',
    'DANG_HOT',
    'DI_TRONG_NGAY',
    'CO_REVIEW',
    null,
  ];

  Future<void> finishSurvey() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Không chọn gì vẫn được.
      // Nếu rỗng thì saveInterests([]) chỉ xóa lựa chọn cũ rồi không thêm mới.
      await authService.saveInterests(OnboardingState.values);

      OnboardingState.clear();

      if (!mounted) return;

      // SỬA Ở ĐÂY:
      // Trước đó đang là AppRoutes.home nên đăng ký xong nhảy thẳng trang chủ.
      // Đổi thành AppRoutes.loading để hiện màn hình chờ trước.
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loading,
        (route) => false,
      );
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

  void skipSurvey() {
    OnboardingState.clear();

    // SỬA Ở ĐÂY:
    // Bỏ qua khảo sát cũng phải qua màn hình chờ.
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.loading,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionLayout(
      title: 'Bạn muốn GoMate ưu\ntiên gợi ý những gì?',
      options: options,
      selectedIndexes: selectedIndexes,
      isLoading: isLoading,
      onToggle: (index) {
        setState(() {
          if (selectedIndexes.contains(index)) {
            selectedIndexes.remove(index);
          } else {
            selectedIndexes.add(index);
          }

          OnboardingState.toggle(optionCodes[index]);
        });
      },
      onNext: finishSurvey,
      onSkip: skipSurvey,
      onBack: () {
        Navigator.pop(context);
      },
    );
  }
}
