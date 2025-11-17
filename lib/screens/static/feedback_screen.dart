import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final ApiService _apiService = ApiService();
  final _contentController = TextEditingController();

  // Các loại phản hồi
  final List<String> _feedbackTypes = ['bug_report', 'suggestion', 'other'];
  String? _selectedType; // Giá trị đang được chọn

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = _feedbackTypes.first; // Đặt giá trị mặc định
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_contentController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập nội dung phản hồi.', isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final message = await _apiService.submitFeedback(
        _selectedType!,
        _contentController.text,
      );
      _showSnackBar(message); // "Cảm ơn bạn!..."
      if (mounted) Navigator.pop(context); // Gửi xong thì thoát
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi Phản hồi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chúng tôi rất mong nhận được góp ý của bạn để cải thiện ứng dụng.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // 1. Dropdown chọn loại
            Text('Loại phản hồi:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _feedbackTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  // Hiển thị tên dễ đọc
                  child: Text(type == 'bug_report' ? 'Báo lỗi' : (type == 'suggestion' ? 'Góp ý' : 'Khác')),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Ô nhập nội dung
            Text('Nội dung:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Nhập mô tả chi tiết của bạn ở đây...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // 3. Nút Gửi
            ElevatedButton(
              onPressed: _isLoading ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Gửi đi'),
            ),
          ],
        ),
      ),
    );
  }
}