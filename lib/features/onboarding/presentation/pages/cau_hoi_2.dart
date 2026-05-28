import 'package:flutter/material.dart';
import 'cau_hoi_1.dart';
import 'package:do_an/app/routes/app_routes.dart';

class CauHoi2Page extends StatefulWidget {
  const CauHoi2Page({super.key});

  @override
  State<CauHoi2Page> createState() => _CauHoi2PageState();
}

class _CauHoi2PageState extends State<CauHoi2Page> {
  final Set<int> selectedIndexes = {2};

  final List<String> options = [
    'Biển đảo / Núi rừng',
    'Thành phố / Trung tâm',
    'Địa danh nổi tiếng',
    'Làng nghề văn hoá / di tích lịch sử',
    'Ngoại ô / Đồng quê',
    'Khác',
  ];

  @override
  Widget build(BuildContext context) {
    return QuestionLayout(
      title: 'Bạn thích khám phá\nnhững đâu?',
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
        Navigator.pushNamed(context, AppRoutes.surveyQuestion3);
      },
      onSkip: () {
        Navigator.pushNamed(context, AppRoutes.surveyQuestion3);
      },
      onBack: () {
        Navigator.pop(context);
      },
    );
  }
}