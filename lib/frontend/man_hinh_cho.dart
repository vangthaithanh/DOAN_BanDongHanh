import 'dart:async';
import 'package:flutter/material.dart';

class ManHinhChoPage extends StatefulWidget {
  const ManHinhChoPage({super.key});

  @override
  State<ManHinhChoPage> createState() => _ManHinhChoPageState();
}

class _ManHinhChoPageState extends State<ManHinhChoPage> {
  int progress = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startLoading();
  }

  void startLoading() {
    timer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted) return;

      if (progress < 100) {
        setState(() {
          progress++;
        });
      } else {
        timer.cancel();

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/trang-chu',
              (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF4AA8FF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 18),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Go',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: 'Mate',
                        style: TextStyle(
                          color: blue,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(flex: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 18,
                      width: double.infinity,
                      color: Colors.white24,
                    ),
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 18,
                          width: MediaQuery.of(context).size.width *
                              (progress / 100) *
                              0.9,
                          color: blue,
                        ),
                      ],
                    ),
                    Text(
                      '$progress%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}