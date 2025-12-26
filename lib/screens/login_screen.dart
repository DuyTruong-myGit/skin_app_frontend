import 'package:flutter/material.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'register_screen.dart';
import 'main_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:app/screens/forgot_password_screen.dart';
import 'package:app/services/google_auth_service.dart';
import 'package:app/services/push_notification_service.dart';

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
  final GoogleAuthService _googleAuthService = GoogleAuthService(); // <--- KHỞI TẠO SERVICE
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

  // === HÀM XỬ LÝ CHUNG: LƯU TOKEN VÀ ĐIỀU HƯỚNG ===
  Future<void> _processLoginSuccess(String token) async {
    // 1. Lưu token
    await _storage.write(key: 'token', value: token);

    // 2. Đồng bộ notification token
    await PushNotificationService.syncTokenToServer();

    // 3. Giải mã JWT (Luôn là Map)
    final Map<String, dynamic> decoded = JwtDecoder.decode(token);

    // 4. Lấy dữ liệu an toàn (Dùng toString() để tránh lỗi kiểu dữ liệu từ Backend)
    // Lưu ý: Kiểm tra chính xác tên trường 'role' và 'userId' trong Payload của bạn
    String userRole = (decoded['role'] ?? 'user').toString();
    String userId = (decoded['userId'] ?? '').toString();

    // 5. Lưu thông tin User
    await _storage.write(key: 'userId', value: userId);
    await _storage.write(key: 'role', value: userRole);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  // === HÀM XỬ LÝ ĐĂNG NHẬP THƯỜNG ===
  Future<void> _handleLogin() async {
    setState(() { _isLoading = true; });

    try {
      final token = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      await _processLoginSuccess(token); // Gọi hàm chung

    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // === HÀM XỬ LÝ ĐĂNG NHẬP GOOGLE ===
  Future<void> _handleGoogleLogin() async {
    setState(() { _isLoading = true; });

    try {
      // 1. Gọi Google Sign In Native
      final googleData = await _googleAuthService.signInWithGoogle();

      if (googleData == null) {
        // User hủy đăng nhập, không làm gì cả
        return;
      }

      // 2. Gửi thông tin Google lên Backend lấy Token
      // googleData chứa: email, googleId, name, photoUrl, idToken
      final token = await _apiService.googleLoginMobile(googleData);

      // 3. Lưu Token và Điều hướng
      await _processLoginSuccess(token);

    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
      // Nếu lỗi, thử đăng xuất Google để lần sau user chọn lại tài khoản được
      await _googleAuthService.signOut();
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
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
                const SizedBox(height: 40),

                // Ô nhập Email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
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
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Nút Quên mật khẩu
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),

                const SizedBox(height: 20),

                // Nút Đăng nhập
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue[800], // Màu chủ đạo
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 30),

                // === PHẦN MỚI: DIVIDER HOẶC ===
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Hoặc", style: TextStyle(color: Colors.grey[600])),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 20),

                // === PHẦN MỚI: NÚT GOOGLE ===
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 30), // Fallback icon
                  ),
                  label: const Text(
                      "Đăng nhập bằng Google",
                      style: TextStyle(color: Colors.black87, fontSize: 16)
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),

                const SizedBox(height: 20),

                // Nút Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Chưa có tài khoản?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}