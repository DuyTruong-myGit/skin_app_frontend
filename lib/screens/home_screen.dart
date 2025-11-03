import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart'; // <-- THÊM VÀO
import 'package:app/services/api_service.dart'; // <-- THÊM VÀO
import 'package:app/screens/result_screen.dart'; // <-- THÊM VÀO
import 'login_screen.dart'; // Import màn hình Login
import 'package:app/screens/history_screen.dart';

class HomeScreen extends StatefulWidget { // SỬA: Chuyển sang StatefulWidget
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> { // SỬA: Thêm State
  final _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker(); // Thêm image picker
  final ApiService _apiService = ApiService(); // Thêm api service

  bool _isLoading = false; // Thêm trạng thái loading

  // Hàm Đăng xuất
  Future<void> _handleLogout(BuildContext context) async {
    await _storage.delete(key: 'token');
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // === THÊM HÀM CHỌN ẢNH VÀ CHẨN ĐOÁN ===
  Future<void> _startDiagnosis() async {
    // 1. Hiển thị dialog chọn Nguồn ảnh
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn nguồn ảnh'),
        actions: [
          TextButton(
            child: const Text('Máy ảnh'),
            onPressed: () => Navigator.pop(context, ImageSource.camera),
          ),
          TextButton(
            child: const Text('Thư viện'),
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return; // Người dùng hủy

    // 2. Lấy ảnh
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return; // Người dùng hủy chọn ảnh

    // 3. Bắt đầu Loading
    setState(() { _isLoading = true; });

    try {
      // 4. Gọi API
      final result = await _apiService.diagnose(image);

      // 5. Chuyển sang Màn hình Kết quả
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(diagnosisResult: result),
          ),
        );
      }
    } catch (e) {
      // 6. Hiển thị lỗi (lỗi 401 đã tự xử lý)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 7. Dừng Loading
      if (mounted) setState(() { _isLoading = false; });
    }
  }
  // ===============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử', // Chú thích khi giữ
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: Center(
        child: _isLoading // HIỂN THỊ LOADING NẾU ĐANG GỌI API
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đăng nhập thành công!',
              style: TextStyle(fontSize: 24, color: Colors.grey[700]),
            ),
            const SizedBox(height: 50),

            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Bắt đầu Chẩn đoán'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: _startDiagnosis, // SỬA: Gọi hàm chẩn đoán
            ),
          ],
        ),
      ),
    );
  }
}