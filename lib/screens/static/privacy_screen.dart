import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính sách Bảo mật'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chính sách Bảo mật',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              '1. Dữ liệu chúng tôi Thu thập',
              'Chúng tôi thu thập các thông tin sau: \n'
                  '• Thông tin tài khoản: Email, Họ và Tên, Mật khẩu (đã mã hóa).\n'
                  '• Dữ liệu người dùng: Hình ảnh bạn tải lên để chẩn đoán.\n'
                  '• Dữ liệu sử dụng: Lịch sử chẩn đoán của bạn.',
            ),
            _buildSection(
              context,
              '2. Cách chúng tôi Sử dụng Dữ liệu',
              'Hình ảnh bạn tải lên được gửi đến máy chủ của chúng tôi và dịch vụ lưu trữ (Cloudinary) để mô hình AI phân tích. Kết quả và hình ảnh được lưu trữ để bạn có thể xem lại trong lịch sử. Chúng tôi cam kết không chia sẻ dữ liệu nhận dạng cá nhân của bạn cho bên thứ ba mà không có sự đồng ý của bạn, trừ khi được yêu cầu bởi pháp luật.',
            ),

            // THAY THẾ BẰNG NỘI DUNG THẬT CỦA BẠN
            _buildSection(
              context,
              '3. Lưu trữ và Bảo mật',
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
            ),
          ],
        ),
      ),
    );
  }

  // Widget tái sử dụng cho các đoạn văn bản
  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}