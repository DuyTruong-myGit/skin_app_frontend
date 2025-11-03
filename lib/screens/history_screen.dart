import 'package:flutter/material.dart';
import 'package:app/models/diagnosis_record.dart'; // Đổi 'app' nếu cần
import 'package:app/services/api_service.dart'; // Đổi 'app' nếu cần
import 'package:intl/intl.dart';
import 'dart:convert'; // <-- THÊM VÀO: Để giải mã JSON
import 'package:app/screens/result_screen.dart';

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
    return DateFormat('HH:mm, Ngày dd/MM/yyyy').format(date);
  }

  // === THÊM HÀM XỬ LÝ KHI NHẤN VÀO MỤC LỊCH SỬ ===
  void _viewHistoryDetail(DiagnosisRecord record) {
    // 1. Kiểm tra xem có dữ liệu JSON để hiển thị không
    if (record.resultJson == null || record.resultJson!.isEmpty) {
      // Hiển thị thông báo nếu không có dữ liệu (hiếm khi xảy ra)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy dữ liệu chi tiết.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // 2. Chuyển đổi chuỗi JSON (String) trở lại thành Map
      final Map<String, dynamic> resultData = json.decode(record.resultJson!);

      // 3. Điều hướng sang ResultScreen và gửi Map đó đi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(diagnosisResult: resultData),
        ),
      );

    } catch (e) {
      // Xử lý nếu JSON bị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi giải mã dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ===============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử Chẩn đoán'),
      ),
      body: FutureBuilder<List<DiagnosisRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          // ... (Các trạng thái loading, error, empty giữ nguyên) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', /* ... */));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bạn chưa có lịch sử chẩn đoán nào.'));
          }

          final historyList = snapshot.data!;

          return ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final record = historyList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  // Thay vì cố tải một ảnh không tồn tại,
                  // chúng ta sẽ hiển thị một Icon placeholder.
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: Icon(
                      Icons.image_search,
                      color: Colors.blue[600],
                    ),
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

                  // SỬA Ở ĐÂY: Gọi hàm _viewHistoryDetail
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