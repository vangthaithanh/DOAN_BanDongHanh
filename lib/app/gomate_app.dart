import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/man_hinh_cho.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class GoMateApp extends StatelessWidget {
  const GoMateApp({super.key});

  bool _isGoogleCallbackRoute(String routeName) {
    return routeName.contains('code=') ||
        routeName.contains('access_token=') ||
        routeName.contains('refresh_token=') ||
        routeName.contains('login-callback');
  }

  Route<dynamic> _buildLoadingRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const ManHinhChoPage(),
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      initialRoute: AppRoutes.start,
      routes: AppRouter.routes,

      // FIX CHÍNH:
      // Khi Google OAuth quay về app bằng route "/?code=..."
      // Flutter mặc định sẽ dựng route "/" trước nên bị nháy form.
      // Đoạn này chặn từ đầu, đưa thẳng vào màn hình chờ.
      onGenerateInitialRoutes: (initialRouteName) {
        if (_isGoogleCallbackRoute(initialRouteName)) {
          return [_buildLoadingRoute(RouteSettings(name: initialRouteName))];
        }

        return [
          MaterialPageRoute(
            builder: AppRouter.routes[AppRoutes.start]!,
            settings: const RouteSettings(name: AppRoutes.start),
          ),
        ];
      },

      // Nếu callback tới khi app đang mở sẵn thì bắt ở đây.
      onGenerateRoute: (settings) {
        final routeName = settings.name ?? '';

        if (_isGoogleCallbackRoute(routeName)) {
          return _buildLoadingRoute(settings);
        }

        return null;
      },

      // Nếu route lạ vẫn lọt xuống đây thì bắt thêm lần nữa.
      onUnknownRoute: (settings) {
        final routeName = settings.name ?? '';

        if (_isGoogleCallbackRoute(routeName)) {
          return _buildLoadingRoute(settings);
        }

        return AppRouter.onUnknownRoute(settings);
      },
    );
  }
}
