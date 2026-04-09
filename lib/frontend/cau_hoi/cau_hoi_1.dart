import 'package:flutter/material.dart';

class CauHoi1Page extends StatefulWidget {
  const CauHoi1Page({super.key});

  @override
  State<CauHoi1Page> createState() => _CauHoi1PageState();
}

class _CauHoi1PageState extends State<CauHoi1Page> {
  final Set<int> selectedIndexes = {2};

  final List<String> options = [
    'Kết thêm bạn bè ở nhiều nơi',
    'Du lịch nghỉ dưỡng',
    'Checkin địa điểm hot, chụp ảnh',
    'Trải nghiệm, khám phá thiên nhiên',
    'Khám phá văn hoá lịch sử',
    'Khám phá ẩm thực vùng miền',
    'Khác',
  ];

  @override
  Widget build(BuildContext context) {
    return QuestionLayout(
      title: 'Bạn thường đi du\nlịch với mục đích gì?',
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
        Navigator.pushNamed(context, '/cau-hoi-2');
      },
      onSkip: () {
        Navigator.pushNamed(context, '/cau-hoi-2');
      },
      onBack: () {
        Navigator.pop(context);
      },
    );
  }
}

class QuestionLayout extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<int> selectedIndexes;
  final ValueChanged<int> onToggle;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const QuestionLayout({
    super.key,
    required this.title,
    required this.options,
    required this.selectedIndexes,
    required this.onToggle,
    required this.onNext,
    required this.onSkip,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF4AA8FF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: onBack,
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
                  const Spacer(),
                  GestureDetector(
                    onTap: onSkip,
                    child: const Text(
                      'Bỏ qua >',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final isSelected = selectedIndexes.contains(index);

                    return GestureDetector(
                      onTap: () => onToggle(index),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? blue : Colors.white70,
                                width: 1.5,
                              ),
                              color: isSelected ? blue : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 13,
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              options[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục →',
                    style: TextStyle(
                      fontSize: 18,
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