import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // Chạy hàm kiểm tra token ngay khi màn hình được tạo
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Đợi 1 chút để logo/loading kịp hiển thị, tạo cảm giác mượt mà
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Đọc token từ bộ nhớ an toàn
      final token = await _storage.read(key: 'token');

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        // Nếu có token, chuyển đến Trang chủ
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Nếu không có token, chuyển đến Đăng nhập
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Nếu có lỗi, cứ về trang đăng nhập
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext
  context) {
    // Màn hình loading đơn giản
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      ),
    );
  }
}