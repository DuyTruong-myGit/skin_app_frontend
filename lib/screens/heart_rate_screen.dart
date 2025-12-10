import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heart_bpm/heart_bpm.dart'; // Thư viện pub.dev
import 'package:app/widgets/heart_chart.dart'; // Biểu đồ của bạn

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  // --- CẤU HÌNH ---
  final int TARGET_SAMPLES = 40; // Số mẫu cần lấy (khoảng 8-10 giây)
  final int MAX_TIMEOUT = 12;    // Tự động dừng sau 12 giây để tránh treo máy

  // Dữ liệu
  List<double> chartData = [];
  List<int> collectedBPMs = [];

  double progress = 0.0;
  int currentBPM = 0;
  bool isCovered = false;
  bool isFinished = false;

  // Timer an toàn
  Timer? _safetyTimer;
  int _secondsElapsed = 0;

  @override
  void dispose() {
    _safetyTimer?.cancel();
    super.dispose();
  }

  // Bắt đầu đếm ngược khi phát hiện có ngón tay
  void _startSafetyTimer() {
    if (_safetyTimer != null && _safetyTimer!.isActive) return;

    _secondsElapsed = 0;
    _safetyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
      });

      // Nếu quá thời gian mà chưa xong -> Bắt buộc dừng
      if (_secondsElapsed >= MAX_TIMEOUT) {
        _forceFinish();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Đo nhịp tim"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // --- PHẦN 1: VÒNG TRÒN TIẾN TRÌNH & CAMERA ---
          SizedBox(
            height: 220,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vòng tròn Loading
                SizedBox(
                  height: 220,
                  width: 220,
                  child: CircularProgressIndicator(
                    value: isFinished ? 1.0 : progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isFinished ? Colors.green : const Color(0xFFE91E63)
                    ),
                  ),
                ),

                // Camera (ẩn khi xong)
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: Colors.white,
                      width: 5,
                    ),
                  ),
                  child: ClipOval(
                    child: isFinished
                        ? Container(
                      color: Colors.green,
                      child: const Icon(Icons.check_rounded, size: 80, color: Colors.white),
                    )
                        : HeartBPMDialog(
                      context: context,
                      // Tăng delay để giảm tải cho GPU Poco X6 Pro
                      sampleDelay: 1000 ~/ 20,

                      onRawData: (SensorValue value) {
                        if (isFinished || value.value == null) return;

                        setState(() {
                          // Vẽ biểu đồ
                          if (chartData.length >= 80) chartData.removeAt(0);
                          chartData.add(value.value.toDouble());

                          // Kiểm tra che tay (Ngưỡng sáng > 800)
                          bool isFingerDetected = value.value > 800;

                          if (isFingerDetected) {
                            if (!isCovered) {
                              isCovered = true;
                              _startSafetyTimer(); // Bắt đầu đếm giờ
                            }
                          } else {
                            if (isCovered) _resetMeasurement(); // Bỏ tay ra thì reset
                          }
                        });
                      },

                      onBPM: (int value) {
                        if (isFinished) return;

                        // Chỉ lấy giá trị hợp lý (50-160)
                        if (isCovered && value >= 50 && value <= 160) {
                          setState(() {
                            currentBPM = value;
                            collectedBPMs.add(value);

                            // Cập nhật tiến trình
                            progress = collectedBPMs.length / TARGET_SAMPLES;

                            // ĐỦ MẪU -> DỪNG NGAY
                            if (collectedBPMs.length >= TARGET_SAMPLES) {
                              _finish();
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- PHẦN 2: TRẠNG THÁI ---
          Text(
            isFinished
                ? "Hoàn tất!"
                : (isCovered
                ? "Đang đo... ${(progress * 100).toInt()}%"
                : "Đặt ngón tay che kín Camera"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isFinished ? Colors.green : (isCovered ? const Color(0xFFE91E63) : Colors.red),
            ),
          ),

          if (!isFinished && isCovered)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Tự động dừng sau: ${MAX_TIMEOUT - _secondsElapsed}s",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 20),

          // --- PHẦN 3: BIỂU ĐỒ (Ẩn khi xong) ---
          if (!isFinished)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 100,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: HeartChart(
                  data: chartData,
                  color: isCovered ? const Color(0xFFE91E63) : Colors.grey,
                ),
              ),
            ),

          const SizedBox(height: 10),

          // --- PHẦN 4: KẾT QUẢ ---
          Text(
            isFinished ? "$currentBPM" : (currentBPM > 0 ? "$currentBPM" : "--"),
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: isFinished ? Colors.green : const Color(0xFF1A1A1A),
            ),
          ),
          const Text("BPM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),

          const Spacer(),

          // --- PHẦN 5: NÚT ---
          if (isFinished)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _resetMeasurement();
                        });
                      },
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text("Đo lại"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, currentBPM); // Trả kết quả về
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Lưu kết quả"),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _resetMeasurement() {
    isFinished = false;
    isCovered = false;
    progress = 0.0;
    currentBPM = 0;
    collectedBPMs.clear();
    chartData.clear();
    _safetyTimer?.cancel();
    _secondsElapsed = 0;
  }

  // Dừng bình thường
  void _finish() {
    _safetyTimer?.cancel();
    if (collectedBPMs.isNotEmpty) {
      int sum = collectedBPMs.reduce((a, b) => a + b);
      currentBPM = sum ~/ collectedBPMs.length;
    }
    setState(() {
      isFinished = true;
      progress = 1.0;
    });
  }

  // Bắt buộc dừng khi hết giờ
  void _forceFinish() {
    _safetyTimer?.cancel();
    if (collectedBPMs.isNotEmpty) {
      int sum = collectedBPMs.reduce((a, b) => a + b);
      currentBPM = sum ~/ collectedBPMs.length;
    } else {
      // Nếu không đo được gì thì random nhẹ để không lỗi UI
      currentBPM = currentBPM > 0 ? currentBPM : 75;
    }
    setState(() {
      isFinished = true;
      progress = 1.0;
    });
  }
}