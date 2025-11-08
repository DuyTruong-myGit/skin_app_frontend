import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _checkDeviceState();
  }

  Future<void> _checkDeviceState() async {
    // Đợi 1 chút để logo/loading kịp hiển thị
    await Future.delayed(const Duration(seconds: 1));

    // 1. Kiểm tra Onboarding trước
    final prefs = await SharedPreferences.getInstance();
    // Mặc định là 'false' nếu chưa có key
    final bool hasSeenOnboarding = prefs.getBool('onboarding_complete') ?? false;

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      // 2. NẾU CHƯA XEM -> Đi đến Onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      // 3. NẾU ĐÃ XEM -> Chạy logic Token như cũ
      _checkLoginStatus();
    }
  }

  Future<void> _checkLoginStatus() async {
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