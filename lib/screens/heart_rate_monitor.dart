import 'package:flutter/material.dart';
import 'package:heart_bpm/heart_bpm.dart';
import 'dart:math' as math;

class HeartRateMonitor extends StatefulWidget {
  const HeartRateMonitor({super.key});

  @override
  State<HeartRateMonitor> createState() => _HeartRateMonitorState();
}

class _HeartRateMonitorState extends State<HeartRateMonitor>
    with SingleTickerProviderStateMixin {
  // Core data
  List<SensorValue> rawData = [];
  List<int> bpmReadings = []; // Lưu 10 lần đo gần nhất
  int? currentBPM;
  int? finalBPM; // Kết quả cuối cùng

  bool isScanning = false;
  bool isMeasurementComplete = false;
  String signalQuality = "Chưa đo";

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Đánh giá chất lượng tín hiệu (chỉ dùng 30 mẫu gần nhất)
  void _evaluateSignalQuality() {
    if (rawData.length < 30) {
      signalQuality = "Thu thập dữ liệu...";
      return;
    }

    // Chỉ lấy 30 mẫu cuối
    final recentData = rawData.sublist(rawData.length - 30);
    final values = recentData.map((e) => e.value).toList();

    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((v) => (v - avg) * (v - avg))
        .reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);

    if (stdDev > 25) {
      signalQuality = "Tín hiệu tốt ✓";
    } else if (stdDev > 12) {
      signalQuality = "Tín hiệu trung bình";
    } else {
      signalQuality = "Tín hiệu yếu - Giữ chặt ngón tay";
    }
  }

  // Tính BPM median từ các lần đo
  int? _calculateMedianBPM() {
    if (bpmReadings.isEmpty) return null;

    final sorted = List<int>.from(bpmReadings)..sort();
    return sorted[sorted.length ~/ 2];
  }

  // Kiểm tra tự động hoàn tất (logic chặt chẽ hơn)
  void _checkAutoComplete() {
    if (isMeasurementComplete) return;

    // Cần ít nhất 10 lần đo
    if (bpmReadings.length < 10) return;

    // Tín hiệu phải tốt
    if (!signalQuality.contains("tốt")) return;

    // Lấy 8 giá trị cuối
    final recent = bpmReadings.sublist(bpmReadings.length - 8);
    final median = _calculateMedianBPM()!;

    // Kiểm tra độ ổn định: 8 giá trị cuối phải nằm trong ±8 BPM so với median
    final isStable = recent.every((bpm) => (bpm - median).abs() <= 8);

    if (isStable) {
      setState(() {
        isScanning = false;
        isMeasurementComplete = true;
        finalBPM = median;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Đo hoàn tất! Nhịp tim: $finalBPM BPM',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Reset đo mới
  void _startNewMeasurement() {
    setState(() {
      rawData.clear();
      bpmReadings.clear();
      currentBPM = null;
      finalBPM = null;
      isScanning = true;
      isMeasurementComplete = false;
      signalQuality = "Chưa đo";
    });
  }

  // Đánh giá mức độ nhịp tim
  String _getBPMCategory(int bpm) {
    if (bpm < 60) return "Chậm";
    if (bpm <= 100) return "Bình thường";
    if (bpm <= 130) return "Hơi nhanh";
    return "Nhanh";
  }

  Color _getBPMColor(int bpm) {
    if (bpm < 60) return Colors.blue;
    if (bpm <= 100) return Colors.green;
    if (bpm <= 130) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final displayBPM = finalBPM ?? _calculateMedianBPM();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Đo Nhịp Tim'),
        backgroundColor: Colors.red[400],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Hướng dẫn
                _buildInstructionCard(),
                const SizedBox(height: 20),

                // Hiển thị BPM chính
                _buildBPMCard(displayBPM),
                const SizedBox(height: 20),

                // Nút điều khiển
                _buildControlButton(),
                const SizedBox(height: 20),

                // Thông số đo (nếu đang đo hoặc đã xong)
                if (isScanning || isMeasurementComplete) _buildStatsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isMeasurementComplete ? Icons.check_circle : Icons.lightbulb_outline,
              color: isMeasurementComplete ? Colors.green[700] : Colors.amber[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isMeasurementComplete
                    ? 'Đo hoàn tất! Ứng dụng tự động dừng khi có đủ dữ liệu chất lượng cao.'
                    : 'Đặt ngón tay lên camera và đèn flash, giữ yên. Ứng dụng sẽ tự động hoàn tất khi đủ dữ liệu.',
                style: TextStyle(fontSize: 13.5, color: Colors.grey[800], height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBPMCard(int? displayBPM) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: HeartBPMDialog(
          context: context,
          onRawData: (value) {
            if (!isScanning) return;
            setState(() {
              // Giới hạn 50 mẫu (đủ cho tính toán)
              if (rawData.length >= 50) rawData.removeAt(0);
              rawData.add(value);
              _evaluateSignalQuality();
            });
          },
          onBPM: (value) {
            if (!isScanning) return;
            setState(() {
              currentBPM = value;
              // Chỉ lưu BPM hợp lệ (40-180 BPM)
              if (value >= 40 && value <= 180) {
                bpmReadings.add(value);
                if (bpmReadings.length > 15) bpmReadings.removeAt(0);
                _checkAutoComplete();
              }
            });
          },
          child: Column(
            children: [
              // Icon trái tim
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  isMeasurementComplete ? Icons.favorite : Icons.favorite_border,
                  size: 70,
                  color: isMeasurementComplete
                      ? Colors.green[400]
                      : (isScanning ? Colors.red[400] : Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 20),

              // Hiển thị BPM
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayBPM?.toString() ?? '--',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: displayBPM != null
                          ? _getBPMColor(displayBPM)
                          : Colors.grey[400],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 5),
                    child: Text(
                      'BPM',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Trạng thái BPM
              if (displayBPM != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getBPMColor(displayBPM).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getBPMColor(displayBPM).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getBPMCategory(displayBPM),
                    style: TextStyle(
                      color: _getBPMColor(displayBPM),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

              // Badge hoàn tất
              if (isMeasurementComplete) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hoàn tất',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton() {
    if (isMeasurementComplete) {
      return ElevatedButton(
        onPressed: _startNewMeasurement,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.refresh, size: 26),
            SizedBox(width: 10),
            Text('Đo Lại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else if (isScanning) {
      return ElevatedButton(
        onPressed: () => setState(() {
          isScanning = false;
          rawData.clear();
          bpmReadings.clear();
          currentBPM = null;
          signalQuality = "Chưa đo";
        }),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.close, size: 26),
            SizedBox(width: 10),
            Text('Hủy Đo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: _startNewMeasurement,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[400],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.play_arrow, size: 26),
            SizedBox(width: 10),
            Text('Bắt Đầu Đo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }

  Widget _buildStatsCard() {
    final progress = (bpmReadings.length / 10).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isMeasurementComplete ? Icons.done_all : Icons.analytics_outlined,
                  color: isMeasurementComplete ? Colors.green[700] : Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  isMeasurementComplete ? 'Kết Quả' : 'Đang Đo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            _buildStatRow('Chất lượng tín hiệu', signalQuality),
            const SizedBox(height: 12),
            _buildStatRow('Số mẫu thu', '${rawData.length}'),
            const SizedBox(height: 12),
            _buildStatRow('BPM hiện tại', currentBPM?.toString() ?? '--'),
            const SizedBox(height: 12),
            _buildStatRow('Số lần đo', '${bpmReadings.length}'),

            if (isScanning && !isMeasurementComplete) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tiến trình',
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ),
                  Text(
                    '${bpmReadings.length}/10',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        SizedBox(width: 8), // tránh dính chữ
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue[700]),
            const SizedBox(width: 10),
            const Text('Hướng Dẫn Sử Dụng'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection(
                '🤖 Chế Độ Tự Động',
                [
                  'Ứng dụng sẽ TỰ ĐỘNG dừng khi:',
                  '  • Thu đủ 10 giá trị BPM',
                  '  • Tín hiệu đạt chất lượng tốt',
                  '  • Nhịp tim ổn định',
                  'Bạn chỉ cần giữ ngón tay yên!',
                ],
              ),
              const SizedBox(height: 15),
              _buildInfoSection(
                '📋 Cách Đo Chính Xác',
                [
                  '• Đặt ngón tay che hoàn toàn camera và flash',
                  '• Giữ yên 15-30 giây',
                  '• Đo ở nơi ánh sáng ổn định',
                  '• Không ấn mạnh, chỉ đặt nhẹ',
                ],
              ),
              const SizedBox(height: 15),
              _buildInfoSection(
                '💚 Giá Trị Bình Thường',
                [
                  '• Người lớn nghỉ: 60-100 BPM',
                  '• Vận động viên: 40-60 BPM',
                  '• Trẻ em (6-15 tuổi): 70-100 BPM',
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lưu ý: Đây chỉ là công cụ tham khảo, không thay thế thiết bị y tế chuyên dụng.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[900],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã Hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            item,
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
          ),
        )),
      ],
    );
  }
}