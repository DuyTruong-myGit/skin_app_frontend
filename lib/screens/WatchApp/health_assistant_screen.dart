import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';
import 'package:app/services/socket_service.dart'; // [MỚI] Import SocketService
import 'package:fl_chart/fl_chart.dart';
import 'package:app/screens/WatchApp/workout_tracking_screen.dart';
import 'dart:async'; // Cần cho StreamSubscription

class HealthAssistantScreen extends StatefulWidget {
  const HealthAssistantScreen({super.key});

  @override
  State<HealthAssistantScreen> createState() => _HealthAssistantScreenState();
}

class _HealthAssistantScreenState extends State<HealthAssistantScreen> {
  final ApiService _apiService = ApiService();

  // [MỚI] Subscription để lắng nghe socket
  StreamSubscription? _socketSubscription;

  bool _isLoading = true;
  String? _linkedDeviceId;

  // Dữ liệu hiển thị
  Map<String, dynamic>? _dailyStats; // Thống kê tổng quan (REST API)
  List<Map<String, dynamic>> _todayHistory = []; // Lịch sử đo (REST + Socket cập nhật thêm)

  // Biến tạm để hiển thị realtime (ghi đè lên thống kê cũ)
  int? _currentHeartRate;
  int? _currentSteps;
  int? _currentSpo2;
  int? _currentCalories;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // 1. Tải dữ liệu cũ từ DB trước
    _setupSocketListener(); // 2. Lắng nghe dữ liệu mới
  }

  @override
  void dispose() {
    _socketSubscription?.cancel(); // Hủy lắng nghe khi thoát màn hình
    super.dispose();
  }

  // --- 1. LOGIC REST API (Lấy quá khứ) ---
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Lấy Profile để check xem đã link đồng hồ chưa
      final profile = await _apiService.getProfile();
      print("🕵️‍♂️ ID CỦA TÔI LÀ: ${profile['id']} - Email: ${profile['email']}");
      final deviceId = profile['watchDeviceId']; // Đảm bảo backend trả về field này

      if (deviceId != null) {
        // Gọi API lấy lịch sử và thống kê hôm nay
        final results = await Future.wait([
          _apiService.getDailyStatistics(), // Thống kê (Avg, Max, Min)
          _apiService.getTodayMeasurements(), // List chi tiết để vẽ biểu đồ
        ]);

        if (mounted) {
          setState(() {
            _linkedDeviceId = deviceId;
            _dailyStats = results[0] as Map<String, dynamic>;
            _todayHistory = List<Map<String, dynamic>>.from(results[1] as List);
          });
        }
      } else {
        if (mounted) setState(() => _linkedDeviceId = null);
      }
    } catch (e) {
      print("Lỗi tải dashboard: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIC SOCKET (Lấy hiện tại) ---
  void _setupSocketListener() {
    // Đảm bảo Socket đã kết nối
    SocketService().connect();

    // Lắng nghe Stream
    _socketSubscription = SocketService().watchDataStream.listen((data) {
      if (!mounted) return;
      print("⚡ Dashboard nhận dữ liệu Realtime: $data");

      setState(() {
        // Cập nhật các chỉ số hiển thị tức thì
        if (data['heartRate'] != null) _currentHeartRate = int.tryParse(data['heartRate'].toString());
        if (data['steps'] != null) _currentSteps = int.tryParse(data['steps'].toString());
        if (data['spO2'] != null) _currentSpo2 = int.tryParse(data['spO2'].toString());
        if (data['calories'] != null) _currentCalories = int.tryParse(data['calories'].toString());

        // Thêm điểm dữ liệu mới vào biểu đồ ngay lập tức
        if (data['heartRate'] != null) {
          _todayHistory.add({
            'heartRate': data['heartRate'],
            'created_at': DateTime.now().toIso8601String(), // Tạo timestamp giả định
          });

          // Giới hạn biểu đồ không quá dài (tùy chọn)
          if (_todayHistory.length > 500) {
            _todayHistory.removeAt(0);
          }
        }
      });
    });
  }


  // Hàm xử lý sự kiện bấm nút Unlink
  Future<void> _handleUnlink() async {
    // Hiển thị hộp thoại xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hủy kết nối?"),
        content: const Text("Bạn có chắc muốn ngắt kết nối với đồng hồ hiện tại không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.unlinkWatch(); // Gọi API
        await _loadInitialData(); // Tải lại màn hình để cập nhật trạng thái
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã hủy kết nối.")));
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  void _showLinkDeviceDialog() {
    final TextEditingController _deviceIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kết nối Đồng hồ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Vui lòng nhập Device ID (được hiển thị trên ứng dụng đồng hồ):"),
            const SizedBox(height: 16),
            TextField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: "Device ID",
                hintText: "Ví dụ: WATCH-12345",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.watch),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final deviceId = _deviceIdController.text.trim();
              if (deviceId.isEmpty) return;

              Navigator.pop(ctx); // Đóng dialog nhập

              // Hiển thị loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              try {
                // Gọi API Link
                await _apiService.linkWatch(deviceId);

                if (mounted) {
                  Navigator.pop(context); // Tắt loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kết nối thành công!")),
                  );
                  // Quan trọng: Tải lại dữ liệu để chuyển sang màn hình Dashboard
                  _loadInitialData();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Tắt loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
            child: const Text("Kết nối", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI ---
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
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadInitialData)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)))
          : (_linkedDeviceId == null ? _buildNotConnectedView() : _buildDashboardView()),
    );
  }

  Widget _buildDashboardView() {
    // Ưu tiên hiển thị dữ liệu Realtime (_current...), nếu null thì dùng dữ liệu thống kê (_dailyStats)

    final heartRateVal = _currentHeartRate?.toString() ?? _dailyStats?['heartRate']?['average']?.toString() ?? '--';
    final spo2Val = _currentSpo2?.toString() ?? _dailyStats?['spO2']?['average']?.toString() ?? '--';
    final stepsVal = _currentSteps?.toString() ?? _dailyStats?['activity']?['totalSteps']?.toString() ?? '--';
    final calVal = _currentCalories?.toString() ?? _dailyStats?['activity']?['totalCalories']?.toString() ?? '--';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(),
          const SizedBox(height: 20),

          // Nút tập luyện
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutTrackingScreen()),
                );
              },
              icon: const Icon(Icons.directions_run, size: 28),
              label: const Text("BẮT ĐẦU LUYỆN TẬP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text("Biến thiên Nhịp tim (Hôm nay)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),

          // Biểu đồ
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
          const Text("Chỉ số hiện tại", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),

          // Thẻ thống kê
          Row(
            children: [
              Expanded(child: _buildStatCard('Nhịp tim', heartRateVal, 'BPM', Icons.favorite, Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('SpO2', spo2Val, '%', Icons.water_drop, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard('Bước chân', stepsVal, 'bước', Icons.directions_walk, Colors.green, isWide: true),
          const SizedBox(height: 12),
          _buildStatCard('Calo tiêu thụ', calVal, 'kcal', Icons.local_fire_department, Colors.orange, isWide: true),
        ],
      ),
    );
  }

  // Widget Biểu đồ (Giữ nguyên logic vẽ, chỉ thay đổi input data)
  Widget _buildHeartRateChart() {
    if (_todayHistory.isEmpty) {
      return const Center(child: Text("Chưa có dữ liệu hôm nay", style: TextStyle(color: Colors.grey)));
    }

    // Sort theo thời gian để vẽ đúng thứ tự
    // Lưu ý: data từ API có thể là DateTime object hoặc String, cần handle cẩn thận
    _todayHistory.sort((a, b) {
      final timeA = DateTime.tryParse(a['created_at'].toString()) ?? DateTime.now();
      final timeB = DateTime.tryParse(b['created_at'].toString()) ?? DateTime.now();
      return timeA.compareTo(timeB);
    });

    List<FlSpot> spots = [];
    for (int i = 0; i < _todayHistory.length; i++) {
      final item = _todayHistory[i];
      final hr = double.tryParse(item['heartRate'].toString()) ?? 0;
      if (hr > 0) {
        spots.add(FlSpot(i.toDouble(), hr));
      }
    }

    // Nếu quá nhiều điểm, chỉ lấy 50 điểm cuối cùng để biểu đồ thoáng
    if (spots.length > 50) {
      spots = spots.sublist(spots.length - 50);
      // Re-index X axis
      spots = spots.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.y)).toList();
    }

    if (spots.isEmpty) return const Center(child: Text("Không có dữ liệu nhịp tim"));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 20)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 40,
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

  // ... (Giữ nguyên các widget UI phụ như _buildStatusHeader, _buildStatCard, _buildNotConnectedView) ...
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
          const Icon(Icons.watch, color: Color(0xFF9C27B0)), // Icon đồng hồ
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Thiết bị đang ghép đôi:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  _linkedDeviceId ?? '...',
                  style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          // [MỚI] Nút Hủy kết nối nhỏ gọn
          IconButton(
            icon: const Icon(Icons.link_off, color: Colors.red),
            tooltip: "Hủy kết nối",
            onPressed: _handleUnlink,
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color, {bool isWide = false}) {
    // ... (Copy y nguyên code UI cũ của bạn) ...
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.watch_off, size: 64, color: Color(0xFF9C27B0)),
            ),
            const SizedBox(height: 24),
            const Text(
              "Chưa kết nối thiết bị",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Kết nối với Smartwatch để theo dõi sức khỏe và nhận cảnh báo theo thời gian thực.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLinkDeviceDialog, // Gọi hàm dialog ở trên
                icon: const Icon(Icons.add_link),
                label: const Text("KẾT NỐI NGAY"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}