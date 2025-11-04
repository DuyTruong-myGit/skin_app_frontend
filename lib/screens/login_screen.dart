import 'package:flutter/material.dart';
import 'package:app/screens/home_screen.dart'; // Đổi 'app' thành tên dự án của bạn nếu khác
import 'package:app/services/api_service.dart'; // Đổi 'app' thành tên dự án của bạn nếu khác
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'register_screen.dart';
import 'main_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    setState(() { _isLoading = true; });

    try {
      final token = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      // 1. Lưu Token
      await _storage.write(key: 'token', value: token);

      // 2. Giải mã Token
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // 3. Lấy role (mặc định là 'user' nếu không có)
      String userRole = decodedToken['role'] ?? 'user';

      // === THÊM VÀO: Lưu cả User ID ===
      String userId = decodedToken['userId'].toString();
      await _storage.write(key: 'userId', value: userId);

      // 4. Lưu Role
      await _storage.write(key: 'role', value: userRole);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Thêm SingleChildScrollView để tránh lỗi khi bàn phím hiện
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // === PHẦN UI ĐÃ BỊ MẤT ===
                const SizedBox(height: 50), // Thêm khoảng đệm
                Text(
                  'CheckMyHealth',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để tiếp tục',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                // ==========================
                const SizedBox(height: 40),

                // Ô nhập Email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration( // <-- PHẦN DECORATION ĐÃ BỊ MẤT
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Ô nhập Mật khẩu
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration( // <-- PHẦN DECORATION ĐÃ BỊ MẤT
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Nút Đăng nhập
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // === PHẦN UI ĐÃ BỊ MẤT ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Chưa có tài khoản?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Đăng ký ngay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
                // ==========================
              ],
            ),
          ),
        ),
      ),
    );
  }
}