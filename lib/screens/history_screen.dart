import 'package:flutter/material.dart';
import 'package:app/models/diagnosis_record.dart'; // Đổi 'app' nếu cần
import 'package:app/services/api_service.dart'; // Đổi 'app' nếu cần
import 'package:intl/intl.dart';
import 'dart:convert'; // Để giải mã JSON
import 'package:app/screens/result_screen.dart'; // Màn hình kết quả

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();

  // SỬA LỖI 1: Dùng 'late' và không dùng '?' (nullable)
  late Future<List<DiagnosisRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    // SỬA LỖI 2: Gán Future trực tiếp, KHÔNG gọi hàm refresh hay setState
    _historyFuture = _apiService.getHistory();
  }

  // SỬA LỖI 3: Hàm refresh BÂY GIỜ mới dùng setState
  // Hàm này chỉ được gọi bởi RefreshIndicator
  Future<void> _refreshHistory() async {
    setState(() {
      // Gán một Future MỚI cho FutureBuilder
      _historyFuture = _apiService.getHistory();
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat("HH:mm, 'Ngày' dd/MM/yyyy").format(date);
  }

  void _viewHistoryDetail(DiagnosisRecord record) {
    // ... (Code xử lý _viewHistoryDetail giữ nguyên)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử Chẩn đoán'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory, // Gọi hàm tải lại khi kéo
        child: FutureBuilder<List<DiagnosisRecord>>(
          future: _historyFuture, // Luôn luôn có 1 future hợp lệ
          builder: (context, snapshot) {
            // 1. TRẠNG THÁI: ĐANG TẢI
            // (Sẽ chạy ở initState và mỗi lần refresh)
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. TRẠNG THÁI: CÓ LỖI
            if (snapshot.hasError) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Text(
                    'Lỗi tải dữ liệu: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // 3. TRẠNG THÁI: KHÔNG CÓ DỮ LIỆU (List rỗng)
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: const Text('Bạn chưa có lịch sử chẩn đoán nào.'),
                ),
              );
            }

            // 4. TRẠNG THÁI: CÓ DỮ LIỆU
            final historyList = snapshot.data!;

            return ListView.builder(
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final record = historyList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: Colors.white,
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        record.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const CircularProgressIndicator(),
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    title: Text(
                      record.diseaseName ?? 'Không rõ bệnh',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937)
                      ),
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
      ),
    );
  }
}