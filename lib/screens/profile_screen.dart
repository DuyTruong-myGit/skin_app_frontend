import 'package:app/screens/verify_reset_code_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart'; // Import màn hình Login
import 'package:app/services/api_service.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  final _fullNameController = TextEditingController();

  // Dùng FutureBuilder để tải
  late Future<Map<String, dynamic>> _profileFuture;

  // Biến lưu trữ thông tin user
  String _email = '';
  String _provider = 'local';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tải profile khi màn hình bắt đầu
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    try {
      final profileData = await _apiService.getProfile();
      // Lưu lại thông tin sau khi tải xong
      _fullNameController.text = profileData['fullName'];
      _email = profileData['email'] ?? '';
      _provider = profileData['provider'] ?? 'local';
      return profileData;
    } catch (e) {
      // Báo lỗi (Lỗi 401 đã tự xử lý)
      _showSnackBar(e.toString(), isError: true);
      rethrow;
    }
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

  // Hàm Đăng xuất
  Future<void> _handleLogout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'role');

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  // Hàm Cập nhật tên
  Future<void> _handleUpdateProfile() async {
    setState(() { _isLoading = true; });
    try {
      final message = await _apiService.updateProfile(_fullNameController.text);
      _showSnackBar(message); // "Cập nhật thành công"
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // Hàm Yêu cầu Đổi mật khẩu
  Future<void> _handleRequestReset() async {
    // === YÊU CẦU CHECK CỦA BẠN (phía Client) ===
    if (_provider != 'local') {
      _showSnackBar('Bạn đang đăng nhập qua $_provider và không thể dùng tính năng này.', isError: true);
      return;
    }
    if (_email.isEmpty) {
      _showSnackBar('Tài khoản của bạn chưa có email, không thể gửi mã.', isError: true);
      return;
    }
    // =======================================

    setState(() { _isLoading = true; });
    try {
      final message = await _apiService.requestPasswordReset();
      _showSnackBar(message); // "Đã gửi mã..."
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyResetCodeScreen()));
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
        title: const Text('Hồ sơ & Cài đặt'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải hồ sơ: ${snapshot.error}'));
          }
          return _buildProfileView(snapshot.data ?? {});
        },
      ),
    );
  }

  // SỬA: Tách _buildProfileView ra và thêm ListView
  Widget _buildProfileView(Map<String, dynamic> profileData) {
    // Lắng nghe provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ListView( // Đổi Column thành ListView
      padding: const EdgeInsets.all(16.0),
      children: [
        // Phần Thông tin
        const Center(
          child: CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(text: _email),
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            filled: true,
            fillColor: Theme.of(context).cardColor.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Họ và Tên',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUpdateProfile,
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.green[600]
          ),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Cập nhật hồ sơ'),
        ),

        const Divider(height: 40),

        // === THÊM PHẦN CHỌN THEME ===
        Text(
          'Giao diện',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        // Dùng SegmentedButton cho trực quan
        SegmentedButton<ThemeModeOption>(
          segments: const [
            ButtonSegment(
              value: ThemeModeOption.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Sáng'),
            ),
            ButtonSegment(
              value: ThemeModeOption.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('Hệ thống'),
            ),
            ButtonSegment(
              value: ThemeModeOption.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Tối'),
            ),
          ],
          selected: {themeProvider.currentThemeOption},
          onSelectionChanged: (Set<ThemeModeOption> newSelection) {
            themeProvider.setThemeMode(newSelection.first);
          },
          style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12)
          ),
        ),
        // ==========================

        const Divider(height: 40),

        // Phần Bảo mật
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRequestReset,
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.orange[700]
          ),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Đổi mật khẩu'),
        ),
        const SizedBox(height: 16),

        // Nút Đăng xuất
        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[400],
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
            _handleLogout();
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}