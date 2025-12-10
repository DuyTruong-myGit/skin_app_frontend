// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:app/services/api_service.dart';
//
// class WorkoutTrackingScreen extends StatefulWidget {
//   const WorkoutTrackingScreen({super.key});
//
//   @override
//   State<WorkoutTrackingScreen> createState() => _WorkoutTrackingScreenState();
// }
//
// class _WorkoutTrackingScreenState extends State<WorkoutTrackingScreen> {
//   final ApiService _apiService = ApiService();
//   Timer? _timer;
//   Map<String, dynamic>? _liveData;
//   final Stopwatch _stopwatch = Stopwatch();
//   String _formattedTime = "00:00:00";
//
//   @override
//   void initState() {
//     super.initState();
//     _startWorkout();
//   }
//
//   void _startWorkout() {
//     _stopwatch.start();
//     // Cập nhật đồng hồ đếm giờ mỗi giây
//     Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) return;
//       setState(() {
//         final duration = _stopwatch.elapsed;
//         _formattedTime =
//         "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
//       });
//     });
//
//     // Gọi API lấy dữ liệu mới nhất mỗi 3 giây (Polling)
//     _fetchLiveData(); // Gọi ngay lần đầu
//     _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       _fetchLiveData();
//     });
//   }
//
//   Future<void> _fetchLiveData() async {
//     try {
//       final data = await _apiService.getLatestWatchData();
//       if (mounted && data != null) {
//         setState(() {
//           _liveData = data;
//         });
//       }
//     } catch (e) {
//       print("Lỗi sync realtime: $e");
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     _stopwatch.stop();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black, // Giao diện tối cho workout
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text("Đang luyện tập", style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Đồng hồ bấm giờ
//           Text(
//             _formattedTime,
//             style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]),
//           ),
//           const Text("Thời gian vận động", style: TextStyle(color: Colors.grey)),
//
//           const SizedBox(height: 50),
//
//           // Nhịp tim to
//           _buildBigMetric(
//             icon: Icons.favorite,
//             color: Colors.redAccent,
//             value: "${_liveData?['heartRate'] ?? '--'}",
//             unit: "BPM",
//             label: "Nhịp tim",
//           ),
//
//           const SizedBox(height: 40),
//
//           // Các chỉ số phụ
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildSmallMetric("Calories", "${_liveData?['calories'] ?? '--'}", "kcal", Icons.local_fire_department, Colors.orange),
//               _buildSmallMetric("Bước chân", "${_liveData?['steps'] ?? '--'}", "bước", Icons.directions_walk, Colors.green),
//               _buildSmallMetric("SpO2", "${_liveData?['spO2'] ?? '--'}", "%", Icons.water_drop, Colors.blue),
//             ],
//           ),
//
//           const Spacer(),
//
//           // Nút dừng
//           Padding(
//             padding: const EdgeInsets.only(bottom: 40),
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 shape: const CircleBorder(),
//                 padding: const EdgeInsets.all(24),
//               ),
//               child: const Icon(Icons.stop, size: 40, color: Colors.white),
//             ),
//           ),
//           const Text("Nhấn giữ để dừng", style: TextStyle(color: Colors.grey, fontSize: 12)),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBigMetric({required IconData icon, required Color color, required String value, required String unit, required String label}) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 40),
//         const SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.baseline,
//           textBaseline: TextBaseline.alphabetic,
//           children: [
//             Text(value, style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: color)),
//             const SizedBox(width: 5),
//             Text(unit, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.withOpacity(0.7))),
//           ],
//         ),
//         Text(label, style: const TextStyle(color: Colors.grey)),
//       ],
//     );
//   }
//
//   Widget _buildSmallMetric(String label, String value, String unit, IconData icon, Color color) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 24),
//         const SizedBox(height: 5),
//         Text("$value $unit", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//         Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
//       ],
//     );
//   }
// }


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';
import 'dart:math';

class WorkoutTrackingScreen extends StatefulWidget {
  const WorkoutTrackingScreen({super.key});

  @override
  State<WorkoutTrackingScreen> createState() => _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends State<WorkoutTrackingScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  Map<String, dynamic>? _liveData;
  final Stopwatch _stopwatch = Stopwatch();
  String _formattedTime = "00:00:00";

  // ========== MOCK DATA ==========
  final Random _random = Random();
  int _baseHeartRate = 75;
  int _currentSteps = 0;
  int _currentCalories = 0;

  Map<String, dynamic> _generateMockLiveData() {
    // Tăng dần nhịp tim khi tập luyện (75 -> 140)
    final elapsedMinutes = _stopwatch.elapsed.inSeconds / 60;

    if (elapsedMinutes < 2) {
      // 2 phút đầu: khởi động (75-95)
      _baseHeartRate = 75 + (elapsedMinutes * 10).toInt();
    } else if (elapsedMinutes < 10) {
      // 2-10 phút: tập mạnh (95-140)
      _baseHeartRate = 95 + ((elapsedMinutes - 2) * 5.6).toInt();
    } else {
      // Sau 10 phút: duy trì (130-145)
      _baseHeartRate = 130 + _random.nextInt(15);
    }

    // Thêm biến động ngẫu nhiên nhỏ ±3
    final heartRate = (_baseHeartRate + _random.nextInt(7) - 3).clamp(60, 180);

    // Tăng bước chân: ~100 bước/phút
    _currentSteps += _random.nextInt(8) + 12; // 12-20 bước mỗi 3 giây

    // Tăng calories: ~8-12 kcal/phút
    _currentCalories += _random.nextInt(2) + 1; // 1-2 kcal mỗi 3 giây

    // SpO2 ổn định 95-99%
    final spo2 = 95 + _random.nextInt(5);

    return {
      'heartRate': heartRate,
      'spO2': spo2,
      'steps': _currentSteps,
      'calories': _currentCalories,
    };
  }
  // ========== END MOCK DATA ==========

  @override
  void initState() {
    super.initState();
    _startWorkout();
  }

  void _startWorkout() {
    _stopwatch.start();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final duration = _stopwatch.elapsed;
        _formattedTime =
        "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
      });
    });

    // MOCK: Gọi ngay lần đầu
    _fetchLiveData();

    // MOCK: Polling mỗi 3 giây
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchLiveData();
    });
  }

  Future<void> _fetchLiveData() async {
    try {
      // MOCK: Thay vì gọi API, tạo dữ liệu giả
      // final data = await _apiService.getLatestWatchData();

      final data = _generateMockLiveData();

      if (mounted && data != null) {
        setState(() {
          _liveData = data;
        });
      }
    } catch (e) {
      print("Lỗi sync realtime: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
          Text(
            _formattedTime,
            style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]),
          ),
          const Text("Thời gian vận động", style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 50),

          _buildBigMetric(
            icon: Icons.favorite,
            color: Colors.redAccent,
            value: "${_liveData?['heartRate'] ?? '--'}",
            unit: "BPM",
            label: "Nhịp tim",
          ),

          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSmallMetric("Calories", "${_liveData?['calories'] ?? '--'}", "kcal", Icons.local_fire_department, Colors.orange),
              _buildSmallMetric("Bước chân", "${_liveData?['steps'] ?? '--'}", "bước", Icons.directions_walk, Colors.green),
              _buildSmallMetric("SpO2", "${_liveData?['spO2'] ?? '--'}", "%", Icons.water_drop, Colors.blue),
            ],
          ),

          const Spacer(),

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

  Widget _buildBigMetric({required IconData icon, required Color color, required String value, required String unit, required String label}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 5),
            Text(unit, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.withOpacity(0.7))),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSmallMetric(String label, String value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 5),
        Text("$value $unit", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}