import 'package:flutter/material.dart';
import 'cau_hoi_1.dart';

class CauHoi3Page extends StatefulWidget {
  const CauHoi3Page({super.key});

  @override
  State<CauHoi3Page> createState() => _CauHoi3PageState();
}

class _CauHoi3PageState extends State<CauHoi3Page> {
  final Set<int> selectedIndexes = {2};

  final List<String> options = [
    'Gần tôi',
    'Local',
    'Đang Hot',
    'Dễ đi trong ngày',
    'Có bài review đi kèm',
    'Khác',
  ];

  @override
  Widget build(BuildContext context) {
    return QuestionLayout(
      title: 'Bạn muốn GoMate ưu\ntiên gợi ý những gì?',
      options: options,
      selectedIndexes: selectedIndexes,
      onToggle: (index) {
        setState(() {
          if (selectedIndexes.contains(index)) {
            selectedIndexes.remove(index);
          } else {
            selectedIndexes.add(index);
          }
        });
      },
      onNext: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/man-hinh-cho',
              (route) => false,
        );
      },
      onSkip: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/man-hinh-cho',
              (route) => false,
        );
      },
      onBack: () {
        Navigator.pop(context);
      },
    );
  }
}