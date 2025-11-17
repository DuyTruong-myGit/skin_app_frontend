import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới thiệu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // TODO: Thay thế bằng Logo thật của bạn
            FlutterLogo(
              size: 100,
            ),
            const SizedBox(height: 16),
            Text(
              'CheckMyHealth',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text('Phiên bản 1.0.0'),
            const SizedBox(height: 30),
            Text(
              'Đây là ứng dụng hỗ trợ chẩn đoán bệnh da liễu sử dụng công nghệ Trí tuệ Nhân tạo (AI).',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Lưu ý: Ứng dụng chỉ mang tính chất tham khảo và không thay thế cho chẩn đoán của bác sĩ chuyên khoa.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Text(
              '© 2025 Nhóm phát triển của bạn. Đã đăng ký bản quyền.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}