import 'package:flutter/material.dart';
import 'package:app/config/app_theme.dart';
import 'package:app/screens/splash_screen.dart';
import 'package:app/services/navigation_service.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/profile_provider.dart';
import 'package:app/services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/services/push_notification_service.dart';

// Đã XÓA import theme_provider.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await initializeDateFormatting('vi_VN', null);
  await Firebase.initializeApp(); // Khởi tạo Firebase
  await PushNotificationService.init(); // Khởi tạo Service thông báo

  runApp(
    MultiProvider(
      providers: [
        // Đã XÓA ThemeProvider ở đây
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Đã XÓA Consumer<ThemeProvider>
    // Trả về trực tiếp MaterialApp
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'CheckMyHealth',

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'), // Tiếng Việt
        Locale('en', 'US'), // Tiếng Anh (dự phòng)
      ],
      locale: const Locale('vi', 'VN'),

      // --- CẤU HÌNH GIAO DIỆN ---
      // Chỉ giữ lại theme sáng
      theme: AppTheme.lightTheme,

      // Đã XÓA darkTheme: ...
      // Đã XÓA themeMode: ...

      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}