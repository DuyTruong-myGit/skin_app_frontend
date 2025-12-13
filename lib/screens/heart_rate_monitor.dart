import 'package:flutter/material.dart';
import 'package:heart_bpm/heart_bpm.dart';

class HeartRateMonitor extends StatefulWidget {
  const HeartRateMonitor({super.key});

  @override
  State<HeartRateMonitor> createState() => _HeartRateMonitorState();
}

class _HeartRateMonitorState extends State<HeartRateMonitor> {
  List<SensorValue> data = [];
  int? bpmValue;
  bool _isMeasuring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInfoDialog(context);
    });
  }

  Widget _buildInfoSection(String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...content.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(item, style: const TextStyle(fontSize: 14, height: 1.4)),
        )),
      ],
    );
  }

  Future<void> _showInfoDialog(BuildContext context) async {
    // 1. Tạm dừng đo (Tắt Flash) trước khi hiện dialog
    setState(() {
      _isMeasuring = false;
    });

    // 2. Hiển thị Dialog và chờ (await) cho đến khi nó đóng lại
    await showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc bấm nút để đóng (hoặc bấm ngoài tùy ý)
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
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
            },
            child: const Text('Đã Hiểu',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // 3. Sau khi Dialog đóng, bật lại chế độ đo (Bật Flash)
    if (mounted) {
      setState(() {
        _isMeasuring = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thêm AppBar để chứa nút Hướng dẫn
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Trong suốt để đẹp hơn
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.deepPurple),
            tooltip: 'Hướng dẫn sử dụng',
            onPressed: () {
              _showInfoDialog(context);
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 22,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isMeasuring
               ? HeartBPMDialog(
                  context: context,
                  onRawData: (value) {
                    setState(() {
                      if (data.length == 100) {
                        data.removeAt(0);
                      }
                      data.add(value);
                    });
                  },
                  onBPM: (value) => setState(() {
                    bpmValue = value;
                  }),
                  child: Text(
                    bpmValue?.toString() ?? "-",
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )
                    : SizedBox(
                  // Placeholder khi tắt Camera
                  width: 100, // Kích thước xấp xỉ camera
                  height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_off,
                          size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text("Đang tạm dừng",
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),

                
              ],
            )
          ],
        ),
      ),
    );
  }
}