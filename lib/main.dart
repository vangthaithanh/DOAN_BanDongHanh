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

  runApp(const GoMateApp());
}
