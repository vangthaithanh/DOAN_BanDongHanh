import 'package:do_an/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/gomate_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CÓ SẴN: đọc file .env
  await dotenv.load(fileName: '.env');

  // CÓ SẴN: khởi tạo Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // THÊM MỚI:
  // Khi user đăng nhập thành công, đặc biệt là Google OAuth,
  // app sẽ tự kiểm tra và tạo profiles + user_settings nếu chưa có.
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;

    if (event == AuthChangeEvent.signedIn) {
      try {
        await AuthService().ensureProfileAfterOAuth();
      } catch (e) {
        debugPrint('ensureProfileAfterOAuth error: $e');
      }
    }
  });

  runApp(const GoMateApp());
}
