import 'package:flutter/material.dart';

class FollowFriendTab extends StatelessWidget {
  final bool isFollowerPage;

  const FollowFriendTab({
    super.key,
    required this.isFollowerPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Text(
                "115 Người theo dõi",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                color: isFollowerPage
                    ? Colors.white
                    : Colors.transparent,
              )
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                "50 Bạn bè",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                color: !isFollowerPage
                    ? Colors.white
                    : Colors.transparent,
              )
            ],
          ),
        ),
      ],
    );
  }
}