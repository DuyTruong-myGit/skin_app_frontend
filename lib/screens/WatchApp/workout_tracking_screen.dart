import 'dart:async';
import 'dart:ui'; // Cần để dùng FontFeature.tabularFigures
import 'package:flutter/material.dart';
import 'package:app/services/socket_service.dart';

class WorkoutTrackingScreen extends StatefulWidget {
  const WorkoutTrackingScreen({super.key});

  @override
  State<WorkoutTrackingScreen> createState() => _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends State<WorkoutTrackingScreen> {
  // Quản lý subscription để hủy khi thoát màn hình
  StreamSubscription? _socketSubscription;

  // Dữ liệu hiển thị: Khởi tạo giá trị mặc định tránh null
  // Dùng Map để dễ merge dữ liệu từ các gói tin khác nhau
  final Map<String, dynamic> _liveData = {
    'heartRate': '--',
    'calories': '--',
    'steps': '--',
    'spO2': '--'
  };

  // Bộ đếm giờ hiển thị trên UI
  final Stopwatch _stopwatch = Stopwatch();
  String _formattedTime = "00:00:00";
  Timer? _displayTimer;

  @override
  void initState() {
    super.initState();
    _startWorkout();
  }

  @override
  void dispose() {
    // Quan trọng: Hủy hết các kết nối khi thoát để tránh rò rỉ bộ nhớ & lỗi log
    _displayTimer?.cancel();
    _socketSubscription?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startWorkout() {
    // 1. Bắt đầu đếm giờ (Logic local của App)
    _stopwatch.start();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final duration = _stopwatch.elapsed;
        _formattedTime =
        "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
      });
    });

    // 2. Kết nối Socket để nhận dữ liệu Realtime
    _connectRealtime();
  }

  void _connectRealtime() {
    // Đảm bảo Socket đã được bật
    SocketService().connect();

    // Lắng nghe luồng dữ liệu
    _socketSubscription = SocketService().watchDataStream.listen((data) {
      if (!mounted) return;

      // In log để debug xem App có nhận được tin hiệu không
      print("🏃 Workout Screen nhận data: $data");

      setState(() {
        // === LOGIC QUAN TRỌNG: MERGE DỮ LIỆU ===
        // Backend gửi 2 loại gói tin:
        // 1. Loại HEALTH: { heartRate: 74, spO2: 97, ... } -> Không có steps
        // 2. Loại WORKOUT: { steps: 136, calories: 5, ... } -> Không có heartRate
        // -> Cần kiểm tra từng trường, chỉ cập nhật nếu có dữ liệu thực

        if (data['heartRate'] != null) {
          _liveData['heartRate'] = data['heartRate'];
        }

        if (data['calories'] != null) {
          _liveData['calories'] = data['calories'];
        }

        if (data['steps'] != null) {
          _liveData['steps'] = data['steps'];
        }

        if (data['spO2'] != null) {
          _liveData['spO2'] = data['spO2'];
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Giao diện tối cho workout
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Đang luyện tập", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Đồng hồ bấm giờ
          Text(
            _formattedTime,
            style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()] // Giữ số không bị nhảy vị trí
            ),
          ),
          const Text("Thời gian vận động", style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 50),

          // Nhịp tim to (Chỉ số quan trọng nhất)
          _buildBigMetric(
            icon: Icons.favorite,
            color: Colors.redAccent,
            value: "${_liveData['heartRate']}",
            unit: "BPM",
            label: "Nhịp tim",
          ),

          const SizedBox(height: 40),

          // Các chỉ số phụ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSmallMetric(
                  "Calories",
                  "${_liveData['calories']}",
                  "kcal",
                  Icons.local_fire_department,
                  Colors.orange
              ),
              _buildSmallMetric(
                  "Bước chân",
                  "${_liveData['steps']}",
                  "bước",
                  Icons.directions_walk,
                  Colors.green
              ),
              _buildSmallMetric(
                  "SpO2",
                  "${_liveData['spO2']}",
                  "%",
                  Icons.water_drop,
                  Colors.blue
              ),
            ],
          ),

          const Spacer(),

          // Nút dừng tập luyện
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
              ),
              child: const Icon(Icons.stop, size: 40, color: Colors.white),
            ),
          ),
          const Text("Nhấn giữ để dừng", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget hiển thị chỉ số lớn (Nhịp tim)
  Widget _buildBigMetric({
    required IconData icon,
    required Color color,
    required String value,
    required String unit,
    required String label
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
                value,
                style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: color
                )
            ),
            const SizedBox(width: 5),
            Text(
                unit,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.7)
                )
            ),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // Widget hiển thị chỉ số nhỏ
  Widget _buildSmallMetric(
      String label,
      String value,
      String unit,
      IconData icon,
      Color color
      ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 5),
        Text(
            "$value $unit",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold
            )
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}