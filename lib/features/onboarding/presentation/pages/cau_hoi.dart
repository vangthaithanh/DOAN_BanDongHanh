import 'package:do_an/app/routes/app_routes.dart';
import 'package:do_an/core/services/auth_service.dart';
import 'package:flutter/material.dart';

class CauHoiPage extends StatelessWidget {
  const CauHoiPage({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF4AA8FF);

    final AuthService authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: authService.getCurrentProfile(),
          builder: (context, snapshot) {
            final profile = snapshot.data;

            final nickname = profile?['nickname'] as String? ?? 'bạn';
            final avatarUrl = profile?['avatar_url'] as String?;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const Spacer(),

                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 26),

                  Text(
                    '“$nickname”',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 28),

                  CircleAvatar(
                    radius: 44,
                    backgroundColor: blue,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 42,
                          )
                        : null,
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Cùng làm một vài khảo\nsát nhỏ nhé',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 23,
                      height: 1.3,
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.surveyQuestion1);
                      },
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
