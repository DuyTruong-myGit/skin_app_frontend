// lib/services/heart_rate_service.dart
import 'dart:math';
import 'package:camera/camera.dart';

class HeartRateService {
  // Hàm tính toán độ sáng trung bình của ảnh (đại diện cho lượng máu đi qua)
  double processCameraImage(CameraImage image) {
    // Chúng ta sử dụng Plane Y (Luminance - Độ sáng) trong hệ màu YUV420
    // Khi tim đập, máu dồn về ngón tay làm ảnh tối đi một chút.
    // Khi tim nghỉ, máu rút đi, ảnh sáng hơn.

    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[0].bytesPerRow;

    // Tối ưu hiệu năng: Không duyệt qua tất cả pixel mà nhảy cóc (step)
    // để giảm tải cho CPU/GPU
    double sum = 0;
    int count = 0;
    const int step = 4; // Đọc 1 pixel, bỏ qua 3 pixel

    // Chỉ quét vùng trung tâm ảnh (nơi đặt ngón tay chắc chắn nhất)
    int margin = height ~/ 4;

    var plane = image.planes[0]; // Plane 0 là Y (Độ sáng)

    for (int y = margin; y < height - margin; y += step) {
      for (int x = margin; x < width - margin; x += step) {
        // Tính index trong mảng byte phẳng
        int index = y * uvRowStride + x;
        if (index < plane.bytes.length) {
          sum += plane.bytes[index];
          count++;
        }
      }
    }

    if (count == 0) return 0;
    return sum / count; // Trả về độ sáng trung bình
  }

  // Thuật toán giả lập tính BPM từ dữ liệu độ sáng
  // (Lưu ý: Thuật toán FFT thực tế rất phức tạp, đây là logic đơn giản hóa cho UI)
  int calculateBPM(List<double> data) {
    // Nếu dữ liệu ít quá hoặc không ổn định, trả về 0
    if (data.length < 30) return 0;

    // Logic demo: Random dao động quanh mức 70-90 để hiển thị
    // Trong môi trường production, bạn cần dùng thư viện FFT (Fast Fourier Transform)
    return 70 + Random().nextInt(15);
  }
}