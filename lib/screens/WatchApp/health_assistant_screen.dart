import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart'; // Import biểu đồ
import 'package:app/screens/WatchApp/workout_tracking_screen.dart';

class HealthAssistantScreen extends StatefulWidget {
  const HealthAssistantScreen({super.key});

  @override
  State<HealthAssistantScreen> createState() => _HealthAssistantScreenState();
}

class _HealthAssistantScreenState extends State<HealthAssistantScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _linkedDeviceId;

  // Dữ liệu cho Dashboard
  Map<String, dynamic>? _dailyStats;
  List<Map<String, dynamic>> _todayHistory = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getProfile();
      final deviceId = profile['watchDeviceId'];

      if (deviceId != null) {
        // Gọi song song 2 API: Lấy thống kê và Lấy lịch sử chi tiết (cho biểu đồ)
        final results = await Future.wait([
          _apiService.getDailyStatistics(),
          _apiService.getTodayMeasurements(),
        ]);

        setState(() {
          _linkedDeviceId = deviceId;
          _dailyStats = results[0] as Map<String, dynamic>;
          _todayHistory = results[1] as List<Map<String, dynamic>>;
        });
      } else {
        setState(() => _linkedDeviceId = null);
      }
    } catch (e) {
      print("Lỗi tải dashboard: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ... (Giữ nguyên hàm _handleLink và _buildNotConnectedView từ code cũ) ...
  // Để gọn code, tôi sẽ chỉ viết lại hàm _buildDashboardView và thêm hàm vẽ biểu đồ

  Future<void> _handleLink(String id) async {
    // (Copy logic cũ của bạn vào đây)
    // ...
    if (id.isEmpty) return;
    try {
      await _apiService.linkWatch(id);
      _loadAllData(); // Tải lại sau khi link
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kết nối thành công!")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text('Trợ lý Sức khỏe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF9C27B0),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadAllData)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)))
          : (_linkedDeviceId == null ? _buildNotConnectedView() : _buildDashboardView()),
    );
  }

  // === UI DASHBOARD CHÍNH ===
  Widget _buildDashboardView() {
    // Lấy dữ liệu thống kê an toàn
    final heartRate = _dailyStats?['heartRate'] ?? {};
    final activity = _dailyStats?['activity'] ?? {};
    final spo2 = _dailyStats?['spO2'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Trạng thái
          _buildStatusHeader(),

          const SizedBox(height: 20),

          // 2. Nút "Bắt đầu theo dõi" (Nổi bật)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutTrackingScreen()),
                ).then((_) => _loadAllData()); // Refresh khi quay về
              },
              icon: const Icon(Icons.directions_run, size: 28),
              label: const Text("BẮT ĐẦU LUYỆN TẬP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63), // Màu hồng đậm nổi bật
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: const Color(0xFFE91E63).withOpacity(0.5),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text("Biến thiên Nhịp tim (Hôm nay)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),

          // 3. Biểu đồ Heart Rate
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: _buildHeartRateChart(),
          ),

          const SizedBox(height: 24),
          const Text("Tổng quan trong ngày", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),

          // 4. Các thẻ thống kê (Dùng dữ liệu Average/Total)
          Row(
            children: [
              Expanded(child: _buildStatCard('Nhịp tim TB', '${heartRate['average'] ?? '--'}', 'BPM', Icons.favorite, Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('SpO2 TB', '${spo2['average'] ?? '--'}', '%', Icons.water_drop, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard('Tổng Bước chân', '${activity['totalSteps'] ?? '--'}', 'bước', Icons.directions_walk, Colors.green, isWide: true),
          const SizedBox(height: 12),
          _buildStatCard('Calo tiêu thụ', '${activity['totalCalories'] ?? '--'}', 'kcal', Icons.local_fire_department, Colors.orange, isWide: true),
        ],
      ),
    );
  }

  // Widget Biểu đồ
  Widget _buildHeartRateChart() {
    if (_todayHistory.isEmpty) {
      return const Center(child: Text("Chưa có dữ liệu hôm nay", style: TextStyle(color: Colors.grey)));
    }

    // Chuẩn bị dữ liệu cho biểu đồ
    // Sắp xếp theo thời gian
    _todayHistory.sort((a, b) => (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''));

    List<FlSpot> spots = [];
    for (int i = 0; i < _todayHistory.length; i++) {
      final item = _todayHistory[i];
      final hr = double.tryParse(item['heartRate'].toString()) ?? 0;
      if (hr > 0) {
        spots.add(FlSpot(i.toDouble(), hr));
      }
    }

    if (spots.isEmpty) return const Center(child: Text("Không có dữ liệu nhịp tim"));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 20)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Ẩn trục X cho gọn
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 40, // Giới hạn trục Y cho đẹp
        maxY: 180,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFE91E63),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFE91E63).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF9C27B0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected, color: Color(0xFF9C27B0)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Đã kết nối: Thiết bị #$_linkedDeviceId",
              style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
            child: const Text("Online", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // (Widget _buildStatCard và _buildNotConnectedView copy lại từ code cũ hoặc dùng lại)
  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color, {bool isWide = false}) {
    // ... (Copy code cũ)
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNotConnectedView() {
    // ... Copy lại hàm này từ code cũ của bạn
    // (Vì code khá dài nên tôi không paste lại để tránh loãng, bạn dùng lại code TextField mà chúng ta đã sửa ở câu trước nhé)
    return Center(child: Text("Chưa kết nối")); // Placeholder
  }
}