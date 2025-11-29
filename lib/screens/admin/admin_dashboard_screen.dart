import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart'; // <-- Thư viện biểu đồ
import 'package:app/config/app_theme.dart';
import 'package:app/screens/admin/admin_user_list_screen.dart';
import 'package:app/screens/admin/admin_feedback_screen.dart';
import 'admin_disease_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _apiService.getAdminStatistics();
  }

  // === HÀM BUILD ĐÃ SỬA ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển Admin'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải thống kê: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Không có dữ liệu.'));
          }

          final stats = snapshot.data!;
          final int totalUsers = stats['totalUsers'] ?? 0;
          final int totalDiagnoses = stats['totalDiagnoses'] ?? 0;

          // Xây dựng giao diện Dashboard
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // 2 Thẻ thống kê
                Row(
                  children: [
                    _buildStatCard('Tổng Người dùng', totalUsers, Icons.person_outline, Colors.blue),
                    const SizedBox(width: 16),
                    // === SỬA LỖI TYPO ICON ===
                    _buildStatCard('Tổng Lượt khám', totalDiagnoses, Icons.medical_services_outlined, Colors.green),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Biểu đồ',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // Biểu đồ tròn
                SizedBox(
                  height: 200,
                  child: _buildPieChart(totalUsers, totalDiagnoses),
                ),
                const SizedBox(height: 24),
                // Menu điều hướng
                Text(
                  'Quản lý',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                // 1. Nút Quản lý Người dùng
                _buildMenuTile(
                  context,
                  title: 'Quản lý Người dùng',
                  icon: Icons.manage_accounts_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminUserListScreen()),
                    );
                  },
                ),

                // 2. Nút Xem Phản hồi (Thêm vào)
                _buildMenuTile(
                  context,
                  title: 'Xem Phản hồi',
                  icon: Icons.feedback_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminFeedbackScreen()),
                    );
                  },
                ),
                _buildMenuTile(
                  context,
                  title: 'QL Thông tin Bệnh lý',
                  icon: Icons.library_books_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminDiseaseListScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // === CÁC HÀM TRỢ GIÚP (NẰM BÊN DƯỚI HÀM BUILD) ===

  // Widget con cho Thẻ thống kê
  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con cho Biểu đồ
  Widget _buildPieChart(int totalUsers, int totalDiagnoses) {
    // (Xử lý trường hợp 0 để tránh lỗi chia cho 0)
    if (totalUsers == 0 && totalDiagnoses == 0) {
      return const Center(child: Text('Chưa có dữ liệu để vẽ biểu đồ'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: totalUsers.toDouble(),
            title: '$totalUsers Users',
            color: Colors.blue,
            radius: 60,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: totalDiagnoses.toDouble(),
            title: '$totalDiagnoses Scans',
            color: Colors.green,
            radius: 60,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
      // Các tùy chọn (options) được truyền trực tiếp vào PieChart
      swapAnimationDuration: const Duration(milliseconds: 150),
      swapAnimationCurve: Curves.linear,
    );
  }

  // Widget con cho Menu
  Widget _buildMenuTile(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        // Gọi tham số 'onTap' đã được truyền vào
        onTap: onTap,
      ),
    );
  }
}