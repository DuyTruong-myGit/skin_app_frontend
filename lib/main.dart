import 'package:flutter/material.dart';
import 'package:app/config/app_theme.dart';
import 'package:app/screens/splash_screen.dart';
import 'package:app/services/navigation_service.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/profile_provider.dart';
void main() {
  runApp(
      MultiProvider( // Dùng MultiProvider để bọc cả 2
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => ProfileProvider()), // Thêm dòng này
        ],
        child: const MyApp(),
      ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe ThemeProvider bằng 'Consumer'
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 'themeProvider' bây giờ đã được định nghĩa
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          title: 'CheckMyHealth',

          theme: AppTheme.lightTheme,      // Theme Sáng
          darkTheme: AppTheme.darkTheme,   // Theme Tối
          themeMode: themeProvider.themeMode, // Lựa chọn của user

          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        );
      },
    );
  }
}