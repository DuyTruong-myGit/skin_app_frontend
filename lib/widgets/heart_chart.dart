import 'package:flutter/material.dart';

class HeartChart extends StatelessWidget {
  final List<double> data;
  final Color color;

  const HeartChart({super.key, required this.data, this.color = Colors.red});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: CustomPaint(
        painter: ChartPainter(data, color),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  ChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    // Tìm min/max để chuẩn hóa dữ liệu về khung hình
    double min = data.reduce((a, b) => a < b ? a : b);
    double max = data.reduce((a, b) => a > b ? a : b);
    double range = max - min;
    if (range == 0) range = 1;

    double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      // Chuẩn hóa giá trị về khoảng 0..1, sau đó map vào chiều cao
      double normalizedY = (data[i] - min) / range;
      double y = size.height - (normalizedY * size.height);
      double x = i * stepX;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}