import 'package:flutter/material.dart';

import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class GoMateApp extends StatelessWidget {
  const GoMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.start,
      routes: AppRouter.routes,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}
