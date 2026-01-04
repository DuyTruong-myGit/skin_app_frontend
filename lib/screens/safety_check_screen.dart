import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/screens/static/emergency_support_screen.dart'; // Import màn hình cấp cứu cũ

class SafetyCheckScreen extends StatefulWidget {
  const SafetyCheckScreen({super.key});

  @override
  State<SafetyCheckScreen> createState() => _SafetyCheckScreenState();
}

class _SafetyCheckScreenState extends State<SafetyCheckScreen> {
  // Danh sách các câu hỏi triệu chứng
  // isEmergency: true = Cần cấp cứu/xử lý ngay (chuyển sang EmergencyScreen)
  // isEmergency: false = Cần đi khám chuyên khoa (chuyển sang Map)
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Vùng da bị chảy máu, rỉ dịch mủ hoặc lở loét không lành?',
      'isEmergency': true,
      'checked': false,
    },
    {
      'question': 'Bạn có bị sốt cao, ớn lạnh hoặc nổi hạch sưng đau gần vùng bệnh?',
      'isEmergency': true,
      'checked': false,
    },
    {
      'question': 'Vùng bệnh lan rộng kích thước rất nhanh chỉ trong vài ngày?',
      'isEmergency': true,
      'checked': false,
    },
    {
      'question': 'Màu sắc vùng da thay đổi bất thường (đen đậm, loang lổ nhiều màu, đỏ rực)?',
      'isEmergency': false,
      'checked': false,
    },
    {
      'question': 'Có cảm giác đau nhức dữ dội, nóng rát hoặc ngứa không chịu nổi?',
      'isEmergency': false,
      'checked': false,
    },
    {
      'question': 'Bề mặt vùng da trở nên sần sùi, thô ráp hoặc đóng vảy cứng?',
      'isEmergency': false,
      'checked': false,
    },
  ];

  void _analyzeSymptoms() {
    bool hasEmergency = _questions.any((q) => q['checked'] == true && q['isEmergency'] == true);
    bool hasWarning = _questions.any((q) => q['checked'] == true && q['isEmergency'] == false);

    if (hasEmergency) {
      // TRƯỜNG HỢP 1: NGUY HIỂM -> Chuyển sang trang Cấp cứu
      _showResultDialog(
        title: "CẢNH BÁO NGUY HIỂM",
        content: "Các triệu chứng bạn gặp phải (chảy máu, sốt, lan nhanh...) là dấu hiệu cần can thiệp y tế NGAY LẬP TỨC.\n\nVui lòng chuyển đến trang hỗ trợ khẩn cấp để gọi cấp cứu hoặc tìm bệnh viện gần nhất.",
        isCritical: true,
        onConfirm: () {
          Navigator.pop(context); // Đóng dialog
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmergencySupportScreen()),
          );
        },
      );
    } else if (hasWarning) {
      // TRƯỜNG HỢP 2: CẦN ĐI KHÁM -> Chuyển sang Map tìm bác sĩ
      _showResultDialog(
        title: "CẦN THĂM KHÁM SỚM",
        content: "Dựa trên các dấu hiệu bạn cung cấp, đây có thể là diễn tiến của bệnh lý da liễu cần bác sĩ chuyên khoa kiểm tra trực tiếp.\n\nHệ thống sẽ giúp bạn tìm các Phòng khám Da liễu hoặc Bệnh viện uy tín quanh đây.",
        isCritical: false,
        onConfirm: () {
          Navigator.pop(context); // Đóng dialog
          _openMapSearch("Bệnh viện da liễu gần đây");
        },
      );
    } else {
      // TRƯỜNG HỢP 3: KHÔNG CÓ TRIỆU CHỨNG ĐƯỢC CHỌN
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một triệu chứng nếu bạn đang gặp phải.')),
      );
    }
  }

  Future<void> _openMapSearch(String query) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Không thể mở bản đồ';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi mở bản đồ: $e')));
      }
    }
  }

  void _showResultDialog({
    required String title,
    required String content,
    required bool isCritical,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isCritical ? Icons.warning_rounded : Icons.info_rounded, color: isCritical ? Colors.red : Colors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(color: isCritical ? Colors.red : Colors.orange[800], fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kiểm tra lại", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCritical ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(isCritical ? "Hỗ trợ Khẩn cấp" : "Tìm Bác sĩ ngay"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kiểm tra Dấu hiệu", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Hãy chọn các dấu hiệu bạn đang gặp phải trong 2-3 ngày gần đây:",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: CheckboxListTile(
                    activeColor: Colors.red,
                    title: Text(
                      _questions[index]['question'],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    value: _questions[index]['checked'],
                    onChanged: (val) {
                      setState(() {
                        _questions[index]['checked'] = val;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: ElevatedButton(
              onPressed: _analyzeSymptoms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F), // Màu đỏ cảnh báo
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: const Text(
                "PHÂN TÍCH RỦI RO NGAY",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}