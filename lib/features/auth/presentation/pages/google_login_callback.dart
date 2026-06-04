import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/routes/app_routes.dart';

class GoogleLoginCallbackPage extends StatefulWidget {
  const GoogleLoginCallbackPage({super.key});

  @override
  State<GoogleLoginCallbackPage> createState() =>
      _GoogleLoginCallbackPageState();
}

class _GoogleLoginCallbackPageState extends State<GoogleLoginCallbackPage> {
  StreamSubscription<AuthState>? authSub;
  bool isNavigated = false;

  @override
  void initState() {
    super.initState();

    // Nếu session đã có rồi thì qua loading luôn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      goLoadingIfLoggedIn();
    });

    // Nếu session chưa kịp có thì nghe sự kiện signedIn.
    authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        goLoadingIfLoggedIn();
      }
    });
  }

  void goLoadingIfLoggedIn() {
    if (!mounted || isNavigated) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return;
    }

    isNavigated = true;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.loading,
      (route) => false,
    );
  }

  @override
  void dispose() {
    authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Màn này chỉ dùng để hứng deep link, không cho hiện "không tìm thấy màn hình".
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Color(0xFF4AA8FF))),
    );
  }
}
