import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart'; // Import màn hình Login

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Khởi tạo storage
  final _storage = const FlutterSecureStorage();

  // === HÀM ĐĂNG XUẤT (Copy từ HomeScreen cũ) ===
  Future<void> _handleLogout(BuildContext context) async {
    // 1. Xóa token và role
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'role'); // Sẽ dùng ở Giai đoạn 4

    if (!context.mounted) return;
    // 2. Quay về màn hình Đăng nhập
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Placeholder cho thông tin user
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tên Người Dùng', // Sẽ lấy từ API sau
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'user@email.com', // Sẽ lấy từ API sau
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Spacer(), // Đẩy nút Đăng xuất xuống dưới cùng

            // Nút Đăng xuất
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                _handleLogout(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}