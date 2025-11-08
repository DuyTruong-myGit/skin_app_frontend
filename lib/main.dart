import 'package:flutter/material.dart';
import 'package:app/config/app_theme.dart';
import 'package:app/screens/splash_screen.dart';
import 'package:app/services/navigation_service.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
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
          title: 'Chẩn đoán Da',

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