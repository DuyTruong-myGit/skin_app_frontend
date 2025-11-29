import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => false; // Không giữ state khi chuyển tab

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // MỖI KHI vào màn hình này, hàm này sẽ tự động được gọi
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔔 Đang tải thông báo mới nhất...');
      final notifs = await _apiService.getNotifications();
      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
      print('✅ Đã tải ${notifs.length} thông báo');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Lỗi tải thông báo: $e');
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat("HH:mm dd/MM").format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Bắt buộc khi dùng AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Bạn không có thông báo nào.'),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: _notifications.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        final isRead = item['is_read'] == 1;

        return Container(
          color: isRead ? Colors.white : Colors.blue[50],
          child: ListTile(
            leading: Icon(
              Icons.notifications,
              color: isRead ? Colors.grey : Colors.blue,
            ),
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
              if (!isRead) {
                try {
                  await _apiService.markNotificationRead(item['notification_id']);
                  // Cập nhật local state
                  setState(() {
                    item['is_read'] = 1;
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e')),
                    );
                  }
                }
              }
            },
          ),
        );
      },
    );
  }
}