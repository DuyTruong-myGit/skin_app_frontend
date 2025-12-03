import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:app/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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

  // --- LOGIC UPLOAD AVATAR GIỮ NGUYÊN ---
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
        if(mounted) context.read<ProfileProvider>().updateAvatarUrl(newUrl);
        _showSnackBar(message);
      } else if (newUrl == null) {
        if(mounted) context.read<ProfileProvider>().updateAvatarUrl(null);
        _showSnackBar(message);
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

  // --- LOGIC CẬP NHẬT TÊN GIỮ NGUYÊN ---
  Future<void> _handleUpdateProfile() async {
    setState(() { _isLoading = true; });
    try {
      final message = await _apiService.updateProfile(_fullNameController.text);
      _showSnackBar(message);
      // Cập nhật lại provider để UI hiển thị tên mới ngay lập tức (nếu provider có hỗ trợ setFullName)
      // context.read<ProfileProvider>().updateFullName(_fullNameController.text);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // === [NEW] LOGIC ĐỔI MẬT KHẨU MỚI (DÙNG DIALOG) ===
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool isDialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Dùng StatefulBuilder để update state trong Dialog
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mật khẩu cũ
                  TextField(
                    controller: oldPassController,
                    obscureText: obscureOld,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setStateDialog(() => obscureOld = !obscureOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mật khẩu mới
                  TextField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      helperText: 'Tối thiểu 8 ký tự, 1 hoa, 1 thường, 1 số, 1 ký tự ĐB',
                      helperMaxLines: 2,
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setStateDialog(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading ? null : () async {
                    if (oldPassController.text.isEmpty || newPassController.text.isEmpty) {
                      _showSnackBar('Vui lòng nhập đầy đủ thông tin', isError: true);
                      return;
                    }

                    // Bắt đầu loading trong dialog
                    setStateDialog(() => isDialogLoading = true);

                    try {
                      final msg = await _apiService.changePassword(
                          oldPassController.text,
                          newPassController.text
                      );

                      if(!mounted) return;
                      Navigator.pop(context); // Đóng dialog
                      _showSnackBar(msg); // Hiện thông báo thành công

                    } catch (e) {
                      if(!mounted) return;
                      // Tắt loading trong dialog để user sửa lại
                      setStateDialog(() => isDialogLoading = false);
                      _showSnackBar(e.toString(), isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isDialogLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- LOGIC KHÁC ---
  Future<void> _handleLogout() async {
    await _apiService.logout();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
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
        title: const Text('Hồ sơ cá nhân', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && profileProvider.profileData == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
          }

          if (profileProvider.profileData == null) {
            return const Center(child: Text('Lỗi tải hồ sơ. Vui lòng thử lại.'));
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
          child: Stack(
            children: [
              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                  gradient: const LinearGradient(colors: [Color(0xFF0066CC), Color(0xFF00B4D8)]),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 64, color: Colors.white),
                  )
                      : const Icon(Icons.person, size: 64, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _isLoading ? null : _handleChangeAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0066CC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // === THÔNG TIN CÁ NHÂN ===
        _buildSectionTitle('Thông tin cá nhân', Icons.person_outline),
        const SizedBox(height: 16),

        _buildCard(
          child: Column(
            children: [
              _buildTextField(controller: TextEditingController(text: email), label: 'Email', icon: Icons.email_outlined, readOnly: true),
              const SizedBox(height: 16),
              _buildTextField(controller: _fullNameController, label: 'Họ và Tên', icon: Icons.person_outline, readOnly: false),
              const SizedBox(height: 20),
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

        // === BẢO MẬT (CHỈ HIỆN KHI DÙNG LOCAL LOGIN) ===
        if (provider == 'local') ...[
          _buildSectionTitle('Bảo mật', Icons.lock_outline),
          const SizedBox(height: 16),

          _buildCard(
            child: _buildSecondaryButton(
              label: 'Đổi mật khẩu',
              icon: Icons.key_outlined,
              // [UPDATE] Gọi hàm hiển thị Dialog thay vì requestReset
              onPressed: _isLoading ? null : _showChangePasswordDialog,
              color: const Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // === ĐĂNG XUẤT ===
        _buildSectionTitle('Tài khoản', Icons.logout),
        const SizedBox(height: 16),
        _buildCard(child: _buildLogoutButton()),
        const SizedBox(height: 32),
      ],
    );
  }

  // --- CÁC WIDGET CON (UI) ---
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(width: 4, height: 22, decoration: BoxDecoration(color: const Color(0xFF0066CC), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Icon(icon, size: 22, color: const Color(0xFF0066CC)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: const Color(0xFF0066CC).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, required bool readOnly}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0066CC), size: 24),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF8FBFF) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required IconData icon, required VoidCallback? onPressed, required bool isLoading, required List<Color> colors}) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(14)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 10), Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))]),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required String label, required IconData icon, required VoidCallback? onPressed, required Color color}) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 22), const SizedBox(width: 10), Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color))]),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFE53935).withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE53935).withOpacity(0.2))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout, color: Color(0xFFE53935), size: 22), SizedBox(width: 10), Text('Đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE53935)))]),
          ),
        ),
      ),
    );
  }
}