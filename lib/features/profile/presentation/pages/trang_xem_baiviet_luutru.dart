import 'package:flutter/material.dart';

import '../../../social/data/models/post_model.dart';
import '../../../social/presentation/widgets/post_card.dart';

class TrangXemBaiVietLuuTruPage extends StatelessWidget {
  final PostModel post;

  const TrangXemBaiVietLuuTruPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Xem bài viết',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            PostCard(
              post: post,
              hienThiTuongTac: false,
              hienThiNutBaCham: false,
            ),
          ],
        ),
      ),
    );
  }
}
