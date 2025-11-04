import 'package:flutter/material.dart';
import 'package:app/models/diagnosis_record.dart'; // Đổi 'app' nếu cần
import 'package:app/services/api_service.dart'; // Đổi 'app' nếu cần
import 'package:intl/intl.dart';
import 'dart:convert'; // Để giải mã JSON

// SỬA LỖI Ở ĐÂY: Xóa chữ 'package' bị lặp
import 'package:app/screens/result_screen.dart'; // Màn hình kết quả

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<DiagnosisRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.getHistory();
  }

  String _formatDate(DateTime date) {
    return DateFormat("HH:mm, 'Ngày' dd/MM/yyyy").format(date);
  }

  // Hàm xử lý khi nhấn vào mục lịch sử
  void _viewHistoryDetail(DiagnosisRecord record) {
    if (record.resultJson == null || record.resultJson!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy dữ liệu chi tiết.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final Map<String, dynamic> resultData = json.decode(record.resultJson!);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(diagnosisResult: resultData),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi giải mã dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử Chẩn đoán'),
      ),
      body: FutureBuilder<List<DiagnosisRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi tải dữ liệu: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Bạn chưa có lịch sử chẩn đoán nào.'),
            );
          }

          final historyList = snapshot.data!;

          return ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final record = historyList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Image.network(
                    record.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const CircularProgressIndicator(),
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                  title: Text(
                    record.diseaseName ?? 'Không rõ bệnh',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _formatDate(record.diagnosedAt),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _viewHistoryDetail(record);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}