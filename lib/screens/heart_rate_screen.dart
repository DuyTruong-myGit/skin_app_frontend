// lib/screens/heart_rate_screen.dart
import 'package:flutter/material.dart';
import 'package:heart_bpm/heart_bpm.dart'; // Thư viện pub.dev
import 'package:app/widgets/heart_chart.dart'; // Biểu đồ sóng của bạn

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  // Cấu hình logic đo
  List<SensorValue> data = [];
  List<double> chartData = [];

  // Danh sách lưu các giá trị BPM hợp lệ để tính trung bình
  List<int> validBpmValues = [];

  // Tiến trình đo (0.0 -> 1.0 tương ứng 0% -> 100%)
  double progress = 0.0;

  int currentBPM = 0; // Giá trị BPM hiện tại đang nhảy
  bool isCovered = false; // Có đang che tay không
  bool isFinished = false; // Đã đo xong chưa

  // Số lượng mẫu cần thu thập để hoàn thành (ví dụ: 100 mẫu ~ 10-12 giây đo chuẩn)
  final int requiredSamples = 100;

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
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // --- PHẦN 1: CAMERA & VÒNG TRÒN TIẾN TRÌNH (GIỐNG YOUTUBE) ---
          SizedBox(
            height: 200,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1.1 Vòng tròn tiến trình (Progress Indicator)
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(
                    value: progress, // Giá trị chạy từ 0 đến 1
                    strokeWidth: 12, // Độ dày vòng tròn
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isFinished ? Colors.green : const Color(0xFFE91E63)
                    ),
                  ),
                ),

                // 1.2 Camera nằm ở giữa (Được cắt hình tròn)
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Nếu đang đo thì viền đỏ, xong thì viền xanh
                    border: Border.all(
                      color: Colors.white,
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: ClipOval(
                    // QUAN TRỌNG: Nếu đo xong (isFinished) thì ẩn Camera đi để tắt đèn Flash
                    child: isFinished
                        ? Container(
                      color: Colors.green,
                      child: const Icon(Icons.check, size: 80, color: Colors.white),
                    )
                        : HeartBPMDialog(
                      context: context,
                      // Giữ delay cao để tránh lag máy Poco
                      sampleDelay: 1000 ~/ 20,

                      // Nhận dữ liệu thô để vẽ biểu đồ & check che tay
                      onRawData: (SensorValue value) {
                        if (value.value == null || isFinished) return;

                        setState(() {
                          // Lưu dữ liệu vẽ biểu đồ
                          if (chartData.length >= 100) chartData.removeAt(0);
                          chartData.add(value.value.toDouble());

                          // Logic check xem có che tay không (Dựa vào độ sáng > 800)
                          bool isFingerDetected = value.value > 800;

                          if (isFingerDetected) {
                            if (!isCovered) isCovered = true;
                          } else {
                            // Nếu bỏ tay ra khi đang đo dở -> Reset lại từ đầu
                            if (isCovered) {
                              isCovered = false;
                              validBpmValues.clear(); // Xóa dữ liệu cũ
                              progress = 0.0; // Reset tiến trình
                              currentBPM = 0;
                            }
                          }
                        });
                      },

                      // Nhận giá trị BPM đã tính toán
                      onBPM: (int value) {
                        if (isFinished) return;

                        // Chỉ lấy giá trị khi đã che tay và giá trị hợp lý (30-200)
                        if (isCovered && value > 30 && value < 200) {
                          setState(() {
                            currentBPM = value;
                            validBpmValues.add(value);

                            // Cập nhật thanh tiến trình
                            progress = validBpmValues.length / requiredSamples;

                            // NẾU ĐÃ ĐỦ MẪU -> DỪNG LẠI (STOP)
                            if (validBpmValues.length >= requiredSamples) {
                              _finishMeasurement();
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

          // --- PHẦN 2: TRẠNG THÁI & HƯỚNG DẪN ---
          Text(
            isFinished
                ? "Đo hoàn tất!"
                : (isCovered ? "Đang đo... ${((progress)*100).toInt()}%" : "Đặt ngón tay lên Camera"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isFinished ? Colors.green : (isCovered ? const Color(0xFFE91E63) : Colors.grey),
            ),
          ),

          if (!isFinished && !isCovered)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "Hãy tìm camera có đèn Flash sáng đỏ",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 30),

          // --- PHẦN 3: BIỂU ĐỒ SÓNG (Chỉ hiện khi đang đo) ---
          if (!isFinished)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 100,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: HeartChart(
                  data: chartData,
                  color: isCovered ? const Color(0xFFE91E63) : Colors.grey,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // --- PHẦN 4: KẾT QUẢ BPM ---
          Text(
            // Nếu xong thì hiện kết quả trung bình, nếu chưa thì hiện số đang nhảy
            isFinished ? "$currentBPM" : (currentBPM > 0 ? "$currentBPM" : "--"),
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: isFinished ? Colors.green : const Color(0xFF1A1A1A),
            ),
          ),
          const Text(
            "BPM (Nhịp/Phút)",
            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),

          const Spacer(),

          // --- PHẦN 5: NÚT KẾT THÚC / ĐO LẠI ---
          if (isFinished)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset để đo lại
                        setState(() {
                          isFinished = false;
                          progress = 0.0;
                          validBpmValues.clear();
                          currentBPM = 0;
                          chartData.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text("Đo lại", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Đóng màn hình và trả về kết quả cho Home
                        Navigator.pop(context, currentBPM);
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

  // HÀM XỬ LÝ KHI ĐO XONG
  void _finishMeasurement() {
    // 1. Tính trung bình cộng các giá trị đã đo để ra số chính xác nhất
    int sum = validBpmValues.reduce((a, b) => a + b);
    int average = sum ~/ validBpmValues.length;

    setState(() {
      isFinished = true;
      currentBPM = average; // Chốt số cuối cùng
      progress = 1.0;
    });

    // Rung nhẹ điện thoại báo hiệu xong (nếu muốn)
  }
}