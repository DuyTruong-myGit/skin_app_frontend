import 'package:app/screens/history_screen.dart';
import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final _searchController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _usersFuture;
  String _searchTerm = '';
  int _currentAdminId = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentAdminId();
    _refreshUsers(isInit: true);
  }

  Future<void> _loadCurrentAdminId() async {
    String? id = await _storage.read(key: 'userId');
    if (mounted) {
      setState(() {
        _currentAdminId = int.tryParse(id ?? '0') ?? 0;
      });
    }
  }

  Future<void> _refreshUsers({bool isInit = false}) async {
    final future = _apiService.getAdminUserList(_searchTerm);
    if (!isInit) {
      setState(() {
        _usersFuture = future;
      });
    } else {
      _usersFuture = future;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleAction(String action, Map<String, dynamic> user) async {
    final int userId = user['user_id'];

    if (action == 'view_history') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HistoryScreen(
            userId: userId,
            userName: user['full_name'],
          ),
        ),
      );
      return;
    }

    String successMessage = '';
    try {
      switch (action) {
        case 'toggle_status':
          final newStatus = user['account_status'] == 'active' ? 'suspended' : 'active';
          successMessage = await _apiService.updateUserStatus(userId, newStatus);
          break;
        case 'toggle_role':
          final newRole = user['role'] == 'user' ? 'admin' : 'user';
          successMessage = await _apiService.updateUserRole(userId, newRole);
          break;
        case 'delete':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Xác nhận Xóa'),
              content: Text('Bạn có chắc muốn XÓA VĨNH VIỄN người dùng ${user['full_name']}? Hành động này không thể hoàn tác.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (confirm == true) {
            successMessage = await _apiService.deleteUser(userId);
          }
          break;
      }

      if (successMessage.isNotEmpty) {
        _showSnackBar(successMessage);
        _refreshUsers();
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm theo tên hoặc email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() { _searchTerm = ''; });
                    _refreshUsers();
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() { _searchTerm = value; });
                _refreshUsers();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshUsers(),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi tải danh sách: ${snapshot.error}'));
                  }

                  // === SỬA LỖI LOGIC Ở ĐÂY ===
                  // 1. Kiểm tra an toàn xem data có null không
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text('Không tìm thấy người dùng nào (null data).'));
                  }

                  final users = snapshot.data!; // <-- Dòng này giờ đã an toàn

                  // 2. Kiểm tra xem list có rỗng không
                  if (users.isEmpty) {
                    return const Center(child: Text('Không tìm thấy người dùng nào (empty list).'));
                  }
                  // ===========================

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final bool isSelf = (user['user_id'] == _currentAdminId);
                      final status = user['account_status'] ?? 'active';
                      final role = user['role'] ?? 'user';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: role == 'admin' ? Colors.blue[50] : Colors.grey[100],
                            child: Icon(
                              role == 'admin' ? Icons.manage_accounts : Icons.person,
                              color: role == 'admin' ? Colors.blue[600] : Colors.grey[600],
                            ),
                          ),
                          title: Text(
                              user['full_name'],
                              style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email']),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(status, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    backgroundColor: status == 'active' ? Colors.green[400] : Colors.orange[400],
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 5),
                                  Chip(
                                    label: Text(role, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    backgroundColor: role == 'admin' ? Colors.blue[400] : Colors.grey[400],
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              )
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _handleAction(value, user),
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'view_history',
                                child: Text('Xem Lịch sử'),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                value: 'toggle_role',
                                enabled: !isSelf,
                                child: Text(user['role'] == 'user' ? 'Nâng lên Admin' : 'Hạ xuống User'),
                              ),
                              PopupMenuItem<String>(
                                value: 'toggle_status',
                                enabled: !isSelf,
                                child: Text(user['account_status'] == 'active' ? 'Đình chỉ' : 'Kích hoạt'),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                value: 'delete',
                                enabled: !isSelf,
                                child: const Text('Xóa người dùng', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}