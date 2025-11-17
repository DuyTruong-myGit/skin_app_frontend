import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';

class VerifyForgotPasswordScreen extends StatefulWidget {
  final String email; // Nhận email từ màn hình trước
  const VerifyForgotPasswordScreen({super.key, required this.email});

  @override
  State<VerifyForgotPasswordScreen> createState() => _VerifyForgotPasswordScreenState();
}

class _VerifyForgotPasswordScreenState extends State<VerifyForgotPasswordScreen> {
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() { _isLoading = true; });
    try {
      final message = await _apiService.publicResetPasswordWithCode(
        widget.email, // Gửi email
        _codeController.text,
        _newPasswordController.text,
      );
      _showSnackBar(message); // "Đổi mật khẩu thành công!"

      if (mounted) {
        // Quay về màn hình Đăng nhập (xóa 2 màn hình Quên MK)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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
        title: const Text('Xác nhận Mật khẩu mới'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Đã gửi mã đến ${widget.email}. Vui lòng nhập mã và mật khẩu mới.'),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mã 6 số',
                prefixIcon: Icon(Icons.pin),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Đặt lại mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}