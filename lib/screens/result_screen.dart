import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> diagnosisResult;

  const ResultScreen({super.key, required this.diagnosisResult});

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ Map
    final String diseaseName = diagnosisResult['disease_name'] ?? 'Không rõ';
    final double confidence = (diagnosisResult['confidence_score'] ?? 0.0) * 100;
    final String description = diagnosisResult['description'] ?? 'Không có mô tả.';
    final String recommendation = diagnosisResult['recommendation'] ?? 'Không có khuyến nghị.';

    // === SỬA LỖI Ở ĐÂY: Lấy URL ảnh ===
    // Dữ liệu này bây giờ đã có sẵn trong diagnosisResult
    final String? imageUrl = diagnosisResult['image_url'];
    // =================================

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả Chẩn đoán'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === SỬA LỖI Ở ĐÂY: Hiển thị ảnh ===
            // (Bỏ comment và thêm kiểm tra null)
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 250, // Tăng chiều cao cho dễ nhìn
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                ),
              ),
            // =================================
            const SizedBox(height: 16),

            Text(
              'Kết quả:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),

            // Tên bệnh
            Text(
              diseaseName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 10),

            // Độ tin cậy
            Text(
              'Độ tin cậy: ${confidence.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),

            // Mô tả
            Text(
              'Mô tả:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // Khuyến nghị
            Text(
              'Khuyến nghị:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(recommendation, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}