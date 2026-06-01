import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'Screens/notification_screen.dart';
import 'Screens/notifiction_service.dart' show NotificationService;
import 'Screens/splash_screen.dart';
import 'Screens/login_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local notifications init
  await NotificationService.init();
  NotificationService.startPolling();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: ApiService.navigatorKey,
          routes: {
            '/login': (context) => const LoginScreen(),
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}