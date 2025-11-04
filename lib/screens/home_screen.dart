import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/api_service.dart';
import 'package:app/screens/result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  // Hàm Đăng xuất (ĐÃ CHUYỂN SANG PROFILE_SCREEN)

  // Hàm chọn ảnh và chẩn đoán
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

    if (source == null) return;

    // 2. Lấy ảnh
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    // 3. Bắt đầu Loading
    setState(() { _isLoading = true; });

    try {
      // 4. Gọi API
      final result = await _apiService.diagnose(image);

      // 5. Chuyển sang Màn hình Kết quả
      if (mounted) {
        // Dùng Navigator.push (không phải replacement)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(diagnosisResult: result),
          ),
        );
      }
    } catch (e) {
      // 6. Hiển thị lỗi
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

  @override
  Widget build(BuildContext context) {
    // SỬA: Không cần Scaffold vì đã có ở MainScreen,
    // nhưng thêm Scaffold để có AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chẩn đoán'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Thêm Icon y tế
              Icon(
                Icons.document_scanner_outlined,
                size: 100,
                color: Colors.blue[200],
              ),
              const SizedBox(height: 20),
              Text(
                'Bắt đầu chẩn đoán da',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Tải ảnh lên để nhận kết quả phân tích từ AI.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              // Nút Bắt đầu (Đã dùng theme chung)
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Tải ảnh lên'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _startDiagnosis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}