import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều khoản Sử dụng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điều khoản Sử dụng',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              '1. Giới thiệu',
              'Chào mừng bạn đến với CheckMyHealth. Bằng cách sử dụng ứng dụng này, bạn đồng ý tuân thủ các điều khoản và điều kiện sau đây. Vui lòng đọc kỹ trước khi sử dụng.',
            ),
            _buildSection(
              context,
              '2. Miễn trừ Trách nhiệm Y tế',
              'Ứng dụng này chỉ cung cấp thông tin tham khảo dựa trên mô hình AI. Thông tin này KHÔNG PHẢI là chẩn đoán y tế chuyên nghiệp và KHÔNG THỂ thay thế cho việc tư vấn, chẩn đoán hoặc điều trị của bác sĩ có chuyên môn. Luôn luôn tìm kiếm lời khuyên của bác sĩ nếu bạn có bất kỳ câu hỏi nào về tình trạng sức khỏe của mình.',
            ),
            _buildSection(
              context,
              '3. Sử dụng Dịch vụ',
              'Bạn đồng ý không sử dụng ứng dụng cho bất kỳ mục đích bất hợp pháp nào. Bạn chịu trách nhiệm về hình ảnh bạn tải lên và đảm bảo rằng bạn có quyền chia sẻ chúng.',
            ),

            // THAY THẾ BẰNG NỘI DUNG THẬT CỦA BẠN
            _buildSection(
              context,
              '4. Quyền Sở hữu Trí tuệ',
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