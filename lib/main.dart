import 'package:flutter/material.dart';
import 'package:app/screens/splash_screen.dart';
import 'package:app/services/navigation_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'Chẩn đoán Da',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Màu chủ đạo
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false, // Tắt banner "Debug"
      home: SplashScreen(),
    );
  }
}