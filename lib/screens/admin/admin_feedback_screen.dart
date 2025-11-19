import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _feedbackFuture;

  @override
  void initState() {
    super.initState();
    _refreshFeedback(isInit: true);
  }

  Future<void> _refreshFeedback({bool isInit = false}) async {
    final future = _apiService.getAdminFeedbackList();
    if (!isInit) {
      setState(() {
        _feedbackFuture = future;
      });
    } else {
      _feedbackFuture = future;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat("HH:mm, 'Ngày' dd/MM/yyyy").format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phản hồi Người dùng'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshFeedback(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _feedbackFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi tải danh sách: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
              return const Center(child: Text('Chưa có phản hồi nào.'));
            }

            final feedbackList = snapshot.data!;

            return ListView.builder(
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final feedback = feedbackList[index];
                final userEmail = feedback['email'] ?? 'Ẩn danh';
                final feedbackType = feedback['feedback_type'] ?? 'other';
                final status = feedback['status'] ?? 'pending'; // Mặc định pending
                final feedbackId = feedback['feedback_id'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: feedbackType == 'bug'
                          ? Colors.red[50]
                          : Colors.blue[50],
                      child: Icon(
                        feedbackType == 'bug'
                            ? Icons.bug_report_outlined
                            : Icons.lightbulb_outline,
                        color: feedbackType == 'bug'
                            ? Colors.red[600]
                            : Colors.blue[600],
                      ),
                    ),
                    title: Text(feedback['content']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Từ: $userEmail'),
                        Text('Loại: $feedbackType'),
                        // Hiển thị trạng thái hiện tại
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: status == 'resolved' ? Colors.green[100] : (status == 'processing' ? Colors.blue[100] : Colors.orange[100]),
                              borderRadius: BorderRadius.circular(4)
                          ),
                          child: Text(
                            status == 'resolved' ? 'Đã giải quyết' : (status == 'processing' ? 'Đang xử lý' : 'Chờ xử lý'),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                color: status == 'resolved' ? Colors.green[800] : (status == 'processing' ? Colors.blue[800] : Colors.orange[800])),
                          ),
                        )
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          // Xử lý xóa
                          await _apiService.deleteFeedback(feedbackId);
                          _refreshFeedback();
                        } else {
                          // Xử lý cập nhật trạng thái (processing/resolved)
                          await _apiService.updateFeedbackStatus(feedbackId, value);
                          _refreshFeedback();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'processing', child: Text('Đánh dấu: Đang xử lý')),
                        const PopupMenuItem(value: 'resolved', child: Text('Đánh dấu: Đã giải quyết')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                      ],
                    ),
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