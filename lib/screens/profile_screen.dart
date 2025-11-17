// import 'package:app/screens/verify_reset_code_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'login_screen.dart'; // Import màn hình Login
// import 'package:app/services/api_service.dart';
// // THÊM CÁC IMPORT CHO VIỆC TẢI ẢNH VÀ THEME
// import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:app/config/app_theme.dart';
// import 'package:app/providers/profile_provider.dart';
// import 'package:provider/provider.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   final ApiService _apiService = ApiService();
//   final _fullNameController = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//
//   bool _isLoading = false;
//
//
//
//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     super.dispose();
//   }
//
//
//   Future<void> _handleChangeAvatar() async {
//     final XFile? originalImage = await _picker.pickImage(source: ImageSource.gallery);
//     if (originalImage == null) return;
//
//     final XFile? croppedImage = await _cropImage(originalImage);
//     if (croppedImage == null) return;
//
//     setState(() { _isLoading = true; });
//
//     try {
//       final result = await _apiService.uploadAvatar(croppedImage);
//       final message = result['message']; // Lấy message
//
// // Lấy URL một cách an toàn (có thể là null)
//       final dynamic newUrl = result['avatar_url'];
//
// // Kiểm tra xem nó có phải là String không
//       if (newUrl is String && newUrl.isNotEmpty) {
//         context.read<ProfileProvider>().updateAvatarUrl(newUrl);
//         _showSnackBar(message);
//       } else if (newUrl == null) {
//         // Nếu backend trả về null (ví dụ: người dùng xóa ảnh)
//         context.read<ProfileProvider>().updateAvatarUrl(null);
//         _showSnackBar(message);
//       } else {
//         // Nếu backend trả về lỗi không mong muốn
//         throw Exception("Lỗi: Server không trả về URL ảnh hợp lệ.");
//       }
//
//     } catch (e) {
//       _showSnackBar(e.toString(), isError: true);
//     } finally {
//       if (mounted) setState(() { _isLoading = false; });
//     }
//   }
//
//   // === CẮT ẢNH (CHO AVATAR) ===
//   Future<XFile?> _cropImage(XFile imageFile) async {
//     final croppedFile = await ImageCropper().cropImage(
//       sourcePath: imageFile.path,
//       aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Vuông
//       compressQuality: 80,
//       uiSettings: [
//         AndroidUiSettings(
//           toolbarTitle: 'Cắt ảnh đại diện',
//           toolbarColor: AppTheme.primaryColor,
//           toolbarWidgetColor: Colors.white,
//           initAspectRatio: CropAspectRatioPreset.square,
//           lockAspectRatio: true,
//         ),
//         IOSUiSettings(
//           title: 'Cắt ảnh đại diện',
//           aspectRatioLockEnabled: true,
//         ),
//       ],
//     );
//     return croppedFile == null ? null : XFile(croppedFile.path);
//   }
//
//   void _showSnackBar(String message, {bool isError = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//       ),
//     );
//   }
//
//   // Hàm Cập nhật tên
//   Future<void> _handleUpdateProfile() async {
//     setState(() { _isLoading = true; });
//     try {
//       final message = await _apiService.updateProfile(_fullNameController.text);
//       _showSnackBar(message);
//     } catch (e) {
//       _showSnackBar(e.toString(), isError: true);
//     } finally {
//       if (mounted) setState(() { _isLoading = false; });
//     }
//   }
//
//   // Hàm Yêu cầu Đổi mật khẩu
//   // Hàm Yêu cầu Đổi mật khẩu
//   Future<void> _handleRequestReset() async {
//     // === SỬA LỖI: ĐỌC DỮ LIỆU TỪ PROVIDER ===
//     final profileData = context.read<ProfileProvider>().profileData;
//     // ===================================
//
//     if (profileData?['provider'] != 'local') {
//       _showSnackBar('Bạn đang đăng nhập qua ${profileData?['provider']}...', isError: true);
//       return;
//     }
//     if (profileData?['email'] == null) {
//       _showSnackBar('Tài khoản của bạn chưa có email...', isError: true);
//       return;
//     }
//
//     // (Phần còn lại của hàm giữ nguyên)
//     setState(() { _isLoading = true; });
//     try {
//       final message = await _apiService.requestPasswordReset();
//       _showSnackBar(message);
//       if (mounted) {
//         Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyResetCodeScreen()));
//       }
//     } catch (e) {
//       _showSnackBar(e.toString(), isError: true);
//     } finally {
//       if (mounted) setState(() { _isLoading = false; });
//     }
//   }
//
//   // Hàm Đăng xuất
//   Future<void> _handleLogout() async {
//     await _apiService.logout();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Hồ sơ cá nhân'),
//       ),
//       body: Consumer<ProfileProvider>(
//         builder: (context, profileProvider, child) {
//           if (profileProvider.isLoading && profileProvider.profileData == null) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           // === THÊM KIỂM TRA NULL ===
//           // Đảm bảo profileData không null trước khi dùng
//           if (profileProvider.profileData == null) {
//             return const Center(child: Text('Lỗi tải hồ sơ. Vui lòng thử lại.'));
//           }
//           // =========================
//
//           // Gán controller (chỉ làm 1 lần)
//           if (_fullNameController.text.isEmpty) {
//             _fullNameController.text = profileProvider.profileData!['fullName'] ?? '';
//           }
//
//           // Truyền dữ liệu profile vào hàm build
//           return _buildProfileView(profileProvider.profileData!);
//         },
//       ),
//     );
//   }
//
// // === GIAO DIỆN HỒ SƠ (ĐỊNH NGHĨA LẠI) ===
// // Hàm này phải nhận 1 tham số tên là 'profileData'
//   Widget _buildProfileView(Map<String, dynamic> profileData) {
//
//     // Lấy dữ liệu từ tham số, không dùng biến state
//     final String email = profileData['email'] ?? 'Đang tải...';
//     final String provider = profileData['provider'] ?? 'local';
//     final String? avatarUrl = profileData['avatar_url']; // Lấy từ provider
//
//     return ListView(
//       padding: const EdgeInsets.all(16.0),
//       children: [
//         // 1. Avatar (Giờ sẽ hiển thị đúng)
//         Center(
//           child: Stack(
//             children: [
//               CircleAvatar(
//                 radius: 60,
//                 backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
//                 child: avatarUrl == null ? const Icon(Icons.person, size: 60) : null,
//               ),
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 child: Material(
//                   color: AppTheme.primaryColor,
//                   borderRadius: BorderRadius.circular(20),
//                   child: InkWell(
//                     onTap: _handleChangeAvatar,
//                     borderRadius: BorderRadius.circular(20),
//                     child: const Padding(
//                       padding: EdgeInsets.all(8.0),
//                       child: Icon(Icons.edit, color: Colors.white, size: 20),
//                     ),
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ),
//         const SizedBox(height: 24),
//
//         // 2. Email (Dùng biến state)
//         TextField(
//           controller: TextEditingController(text: email),
//           readOnly: true,
//           decoration: InputDecoration(
//             labelText: 'Email',
//             prefixIcon: Icon(Icons.email_outlined),
//             filled: true,
//             fillColor: Theme.of(context).cardColor.withOpacity(0.5),
//           ),
//         ),
//         const SizedBox(height: 16),
//
//         // 3. Tên
//         TextField(
//           controller: _fullNameController, // (Đã gán trong hàm build)
//           decoration: const InputDecoration(
//             labelText: 'Họ và Tên',
//             prefixIcon: Icon(Icons.person_outline),
//           ),
//         ),
//         const SizedBox(height: 20),
//
//         // 4. Nút Cập nhật Tên
//         ElevatedButton(
//           onPressed: _isLoading ? null : _handleUpdateProfile,
//           style: ElevatedButton.styleFrom(
//               minimumSize: const Size(double.infinity, 50),
//               backgroundColor: Colors.green[600]),
//           child: _isLoading
//               ? const CircularProgressIndicator(color: Colors.white)
//               : const Text('Cập nhật hồ sơ'),
//         ),
//
//         const Divider(height: 40),
//
//         // 5. Nút Đổi mật khẩu
//         if (provider == 'local') // (Dùng biến state)
//           ElevatedButton(
//             onPressed: _isLoading ? null : _handleRequestReset,
//             style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 50),
//                 backgroundColor: Colors.orange[700]),
//             child: _isLoading
//                 ? const CircularProgressIndicator(color: Colors.white)
//                 : const Text('Đổi mật khẩu'),
//           ),
//         const SizedBox(height: 16),
//
//         // 6. Nút Đăng xuất
//         OutlinedButton.icon(
//           icon: const Icon(Icons.logout),
//           label: const Text('Đăng xuất'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.red[400],
//             side: BorderSide(color: Colors.red[100]!),
//             minimumSize: const Size(double.infinity, 50),
//           ),
//           onPressed: _handleLogout,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
// }







import 'package:app/screens/verify_reset_code_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import 'package:app/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:app/config/app_theme.dart';
import 'package:app/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _fullNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleChangeAvatar() async {
    final XFile? originalImage = await _picker.pickImage(source: ImageSource.gallery);
    if (originalImage == null) return;

    final XFile? croppedImage = await _cropImage(originalImage);
    if (croppedImage == null) return;

    setState(() { _isLoading = true; });

    try {
      final result = await _apiService.uploadAvatar(croppedImage);
      final message = result['message'];

      final dynamic newUrl = result['avatar_url'];

      if (newUrl is String && newUrl.isNotEmpty) {
        context.read<ProfileProvider>().updateAvatarUrl(newUrl);
        _showSnackBar(message);
      } else if (newUrl == null) {
        context.read<ProfileProvider>().updateAvatarUrl(null);
        _showSnackBar(message);
      } else {
        throw Exception("Lỗi: Server không trả về URL ảnh hợp lệ.");
      }

    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<XFile?> _cropImage(XFile imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 80,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt ảnh đại diện',
          toolbarColor: const Color(0xFF0066CC),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Cắt ảnh đại diện',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    return croppedFile == null ? null : XFile(croppedFile.path);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleUpdateProfile() async {
    setState(() { _isLoading = true; });
    try {
      final message = await _apiService.updateProfile(_fullNameController.text);
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleRequestReset() async {
    final profileData = context.read<ProfileProvider>().profileData;

    if (profileData?['provider'] != 'local') {
      _showSnackBar('Bạn đang đăng nhập qua ${profileData?['provider']}...', isError: true);
      return;
    }
    if (profileData?['email'] == null) {
      _showSnackBar('Tài khoản của bạn chưa có email...', isError: true);
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final message = await _apiService.requestPasswordReset();
      _showSnackBar(message);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyResetCodeScreen()));
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleLogout() async {
    await _apiService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && profileProvider.profileData == null) {
            return Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066CC).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            );
          }

          if (profileProvider.profileData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: const Color(0xFFE53935).withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lỗi tải hồ sơ. Vui lòng thử lại.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            );
          }

          if (_fullNameController.text.isEmpty) {
            _fullNameController.text = profileProvider.profileData!['fullName'] ?? '';
          }

          return _buildProfileView(profileProvider.profileData!);
        },
      ),
    );
  }

  Widget _buildProfileView(Map<String, dynamic> profileData) {
    final String email = profileData['email'] ?? 'Đang tải...';
    final String provider = profileData['provider'] ?? 'local';
    final String? avatarUrl = profileData['avatar_url'];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // === AVATAR SECTION ===
        Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066CC).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    gradient: avatarUrl == null
                        ? const LinearGradient(
                      colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                  ),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.person, size: 64, color: Colors.white),
                        );
                      },
                    )
                        : const Icon(Icons.person, size: 64, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066CC).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleChangeAvatar,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // === THÔNG TIN CÁ NHÂN SECTION ===
        _buildSectionTitle('Thông tin cá nhân', Icons.person_outline),
        const SizedBox(height: 16),

        _buildCard(
          child: Column(
            children: [
              // Email field
              _buildTextField(
                controller: TextEditingController(text: email),
                label: 'Email',
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Full name field
              _buildTextField(
                controller: _fullNameController,
                label: 'Họ và Tên',
                icon: Icons.person_outline,
                readOnly: false,
              ),
              const SizedBox(height: 20),

              // Update profile button
              _buildPrimaryButton(
                label: 'Cập nhật hồ sơ',
                icon: Icons.check_circle_outline,
                onPressed: _isLoading ? null : _handleUpdateProfile,
                isLoading: _isLoading,
                colors: const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // === BẢO MẬT SECTION ===
        if (provider == 'local') ...[
          _buildSectionTitle('Bảo mật', Icons.lock_outline),
          const SizedBox(height: 16),

          _buildCard(
            child: _buildSecondaryButton(
              label: 'Đổi mật khẩu',
              icon: Icons.key_outlined,
              onPressed: _isLoading ? null : _handleRequestReset,
              color: const Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // === ĐĂNG XUẤT SECTION ===
        _buildSectionTitle('Tài khoản', Icons.logout),
        const SizedBox(height: 16),

        _buildCard(
          child: _buildLogoutButton(),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 22, color: const Color(0xFF0066CC)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066CC).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool readOnly,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF666666),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          child: Icon(icon, color: const Color(0xFF0066CC), size: 24),
        ),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF8FBFF) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isLoading,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.2), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Color(0xFFE53935), size: 22),
                SizedBox(width: 10),
                Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE53935),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}