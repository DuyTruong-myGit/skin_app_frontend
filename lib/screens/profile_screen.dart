import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:app/providers/profile_provider.dart';
import 'package:provider/provider.dart';

// Import màn hình Login nếu cần điều hướng sau khi logout
import 'login_screen.dart';

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

  // Màu sắc theo Design System
  static const Color primaryBlue = Color(0xFF0066CC);
  static const Color bgOffWhite = Color(0xFFF9FAFB);
  static const Color borderGrey = Color(0xFFE0E0E0);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  // --- LOGIC GIỮ NGUYÊN (Avatar, Update, Password, Logout) ---

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
          toolbarColor: primaryBlue,
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

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool isDialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Radius 12 chuẩn hơn
              title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogInput(
                    controller: oldPassController,
                    label: 'Mật khẩu hiện tại',
                    obscure: obscureOld,
                    onToggle: () => setStateDialog(() => obscureOld = !obscureOld),
                  ),
                  const SizedBox(height: 12),
                  _buildDialogInput(
                    controller: newPassController,
                    label: 'Mật khẩu mới',
                    obscure: obscureNew,
                    onToggle: () => setStateDialog(() => obscureNew = !obscureNew),
                    helperText: 'Tối thiểu 8 ký tự, bao gồm chữ hoa, thường, số và ký tự đặc biệt.',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading ? null : () async {
                    if (oldPassController.text.isEmpty || newPassController.text.isEmpty) {
                      _showSnackBar('Vui lòng nhập đầy đủ thông tin', isError: true);
                      return;
                    }
                    setStateDialog(() => isDialogLoading = true);
                    try {
                      final msg = await _apiService.changePassword(oldPassController.text, newPassController.text);
                      if(!mounted) return;
                      Navigator.pop(context);
                      _showSnackBar(msg);
                    } catch (e) {
                      if(!mounted) return;
                      setStateDialog(() => isDialogLoading = false);
                      _showSnackBar(e.toString(), isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: isDialogLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await _apiService.logout();
    // Navigator logic should be handled here or in the calling screen
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // === UI BUILD ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgOffWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && profileProvider.profileData == null) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          }
          if (profileProvider.profileData == null) {
            return const Center(child: Text('Lỗi tải hồ sơ. Vui lòng thử lại.'));
          }

          // Sync data to controller only if empty
          if (_fullNameController.text.isEmpty) {
            _fullNameController.text = profileProvider.profileData!['fullName'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildBody(profileProvider.profileData!),
          );
        },
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> profileData) {
    final String email = profileData['email'] ?? 'Đang tải...';
    final String provider = profileData['provider'] ?? 'local';
    final String? avatarUrl = profileData['avatar_url'];

    return Column(
      children: [
        // 1. AVATAR SECTION
        _buildAvatarSection(avatarUrl),

        const SizedBox(height: 32),

        // 2. THÔNG TIN CÁ NHÂN
        _buildSectionHeader('Thông tin chung'),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderGrey),
          ),
          child: Column(
            children: [
              _buildCleanInput(
                  label: 'Email',
                  value: email,
                  icon: Icons.email_outlined,
                  isReadOnly: true
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 16),
              _buildCleanInput(
                  label: 'Họ và tên',
                  controller: _fullNameController,
                  icon: Icons.person_outline,
                  isReadOnly: false
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleUpdateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Lưu thay đổi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),

        const SizedBox(height: 32),

        // 3. BẢO MẬT (Nếu là local)
        if (provider == 'local') ...[
          _buildSectionHeader('Bảo mật'),
          const SizedBox(height: 12),
          _buildActionCard(
            title: 'Đổi mật khẩu',
            icon: Icons.lock_outline,
            onTap: _showChangePasswordDialog,
            textColor: Colors.black87,
          ),
          const SizedBox(height: 24),
        ],

        // 4. LOGOUT
        _buildActionCard(
          title: 'Đăng xuất',
          icon: Icons.logout,
          onTap: _handleLogout,
          textColor: Colors.red.shade600,
          isDanger: true,
        ),
      ],
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildAvatarSection(String? url) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300, width: 1),
              image: url != null
                  ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                  : null,
            ),
            child: url == null
                ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _isLoading ? null : _handleChangeAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5
        ),
      ),
    );
  }

  // Input Field tinh gọn, không border bao quanh từng field mà nằm trong container chung
  Widget _buildCleanInput({
    required String label,
    TextEditingController? controller,
    String? value,
    required IconData icon,
    required bool isReadOnly,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: textSecondary)),
              const SizedBox(height: 4),
              isReadOnly
                  ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(value ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              )
                  : TextField(
                controller: controller,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: 'Nhập thông tin...',
                ),
              ),
            ],
          ),
        ),
        if (!isReadOnly) Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
      ],
    );
  }

  // Card cho các hành động (Đổi pass, Logout)
  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color textColor,
    bool isDanger = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: isDanger ? Colors.red.shade100 : borderGrey),
            borderRadius: BorderRadius.circular(8),
            color: isDanger ? Colors.red.shade50.withOpacity(0.5) : Colors.white,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: isDanger ? Colors.red.shade300 : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // Input riêng cho Dialog
  Widget _buildDialogInput({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
        labelStyle: const TextStyle(fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryBlue)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
          onPressed: onToggle,
        ),
      ),
    );
  }
}