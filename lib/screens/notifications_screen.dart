import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _notifFuture;

  @override
  void initState() {
    super.initState();
    _notifFuture = _apiService.getNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _notifFuture = _apiService.getNotifications();
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat("HH:mm dd/MM").format(date); // Ví dụ: 14:30 19/11
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notifFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Bạn không có thông báo nào.'));
            }

            final notifs = snapshot.data!;
            return ListView.separated(
              itemCount: notifs.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = notifs[index];
                final isRead = item['is_read'] == 1; // MySQL trả về 1 cho true

                return Container(
                  color: isRead ? Colors.white : Colors.blue[50], // Chưa đọc thì màu xanh nhạt
                  child: ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.blue),
                    title: Text(
                      item['title'] ?? '',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['message'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(item['created_at']),
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    onTap: () async {
                      // Khi bấm vào thì đánh dấu đã đọc
                      if (!isRead) {
                        await _apiService.markNotificationRead(item['notification_id']);
                        _refresh(); // Tải lại để cập nhật màu
                      }
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