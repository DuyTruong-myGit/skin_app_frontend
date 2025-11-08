import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/api_service.dart';
import 'package:app/screens/result_screen.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:app/config/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  // === THÊM HÀM MỚI: CẮT ẢNH ===
  Future<XFile?> _cropImage(XFile imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      // Cấu hình giao diện cắt ảnh
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt & Xoay ảnh',
          toolbarColor: AppTheme.primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Cắt & Xoay ảnh',
        ),
      ],
    );
    // Trả về file đã cắt (hoặc null nếu user hủy)
    return croppedFile == null ? null : XFile(croppedFile.path);
  }

  // Hàm chọn ảnh và chẩn đoán (ĐÃ CẬP NHẬT)
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

    // 2. Lấy ảnh (gốc)
    final XFile? originalImage = await _picker.pickImage(source: source);
    if (originalImage == null) return;

    // === SỬA Ở ĐÂY: Thêm bước Cắt ảnh ===
    // 3. Cắt ảnh
    final XFile? croppedImage = await _cropImage(originalImage);
    if (croppedImage == null) return; // User hủy ở bước cắt
    // ==================================

    // 4. Bắt đầu Loading
    setState(() { _isLoading = true; });

    try {
      // 5. Gọi API (gửi ảnh ĐÃ CẮT)
      final result = await _apiService.diagnose(croppedImage);

      // 6. Chuyển sang Màn hình Kết quả
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(diagnosisResult: result),
          ),
        );
      }
    } catch (e) {
      // 7. Hiển thị lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 8. Dừng Loading
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