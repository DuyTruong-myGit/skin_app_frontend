// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:app/providers/theme_provider.dart';
// import 'package:app/services/api_service.dart'; // Vẫn cần cho nút Logout
//
// // Import các trang
// import 'package:app/screens/static/about_screen.dart';
// import 'package:app/screens/static/privacy_screen.dart';
// import 'package:app/screens/static/terms_screen.dart';
// import 'package:app/screens/profile_screen.dart'; // <-- SỬA: Import ProfileScreen
// import 'package:app/screens/static/privacy_screen.dart';
// import 'package:app/screens/static/feedback_screen.dart';// Import FeedbackScreen
//
// class SettingsScreen extends StatelessWidget { // SỬA: Đổi thành StatelessWidget
//   const SettingsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = context.watch<ThemeProvider>();
//     final apiService = ApiService(); // Khởi tạo service cho nút Logout
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Cài đặt')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//
//           // === THÊM NÚT HỒ SƠ CÁ NHÂN ===
//           Text('Tài khoản', style: Theme.of(context).textTheme.titleMedium),
//           const SizedBox(height: 8),
//           ListTile(
//             leading: const Icon(Icons.person_outline),
//             title: const Text('Hồ sơ cá nhân'),
//             subtitle: const Text('Thay đổi tên, ảnh đại diện, mật khẩu'),
//             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//             onTap: () {
//               // Điều hướng sang ProfileScreen
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const ProfileScreen()),
//               );
//             },
//             shape: RoundedRectangleBorder( // Thêm viền
//                 borderRadius: BorderRadius.circular(12),
//                 side: BorderSide(color: Theme.of(context).dividerColor)
//             ),
//           ),
//           // ==============================
//
//           const Divider(height: 32),
//
//           Text('Giao diện', style: Theme.of(context).textTheme.titleMedium),
//           const SizedBox(height: 8),
//           // (Code SegmentedButton cho Theme giữ nguyên)
//           SegmentedButton<ThemeModeOption>(
//             segments: const [
//               ButtonSegment(value: ThemeModeOption.light, icon: Icon(Icons.light_mode_outlined), label: Text('Sáng')),
//               ButtonSegment(value: ThemeModeOption.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Hệ thống')),
//               ButtonSegment(value: ThemeModeOption.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Tối')),
//             ],
//             selected: {themeProvider.currentThemeOption},
//             onSelectionChanged: (Set<ThemeModeOption> s) => themeProvider.setThemeMode(s.first),
//           ),
//
//           const Divider(height: 32),
//           Text('Hỗ trợ & Pháp lý', style: Theme.of(context).textTheme.titleMedium),
//
//           // (Code các ListTile: Phản hồi, Điều khoản, Chính sách, Giới thiệu giữ nguyên)
//           ListTile(
//             leading: const Icon(Icons.feedback_outlined),
//             title: const Text('Gửi phản hồi / Báo lỗi'),
//             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const FeedbackScreen()),
//               );
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.description_outlined),
//             title: const Text('Điều khoản sử dụng'),
//             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const TermsScreen()),
//               );
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.privacy_tip_outlined),
//             title: const Text('Chính sách quyền riêng tư'),
//             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const PrivacyScreen()),
//               );
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.info_outline),
//             title: const Text('Giới thiệu'),
//             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AboutScreen()),
//               );
//             },
//           ),
//
//           const SizedBox(height: 16),
//           // === SỬA: NÚT ĐĂNG XUẤT ĐÃ CHUYỂN SANG PROFILE ===
//           // (Đã xóa nút Logout khỏi đây)
//         ],
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:app/services/api_service.dart';

// Import các trang
import 'package:app/screens/static/about_screen.dart';
import 'package:app/screens/static/privacy_screen.dart';
import 'package:app/screens/static/terms_screen.dart';
import 'package:app/screens/profile_screen.dart';
import 'package:app/screens/static/feedback_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final apiService = ApiService();

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
          'Cài đặt',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === TÀI KHOẢN SECTION ===
          _buildSectionTitle(context, 'Tài khoản', Icons.account_circle_outlined),
          const SizedBox(height: 12),
          _buildCard(
            context,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066CC).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_outline, color: Colors.white, size: 26),
              ),
              title: const Text(
                'Hồ sơ cá nhân',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  height: 1.3,
                ),
              ),
              subtitle: const Text(
                'Thay đổi tên, ảnh đại diện, mật khẩu',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              trailing: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF0066CC),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // === GIAO DIỆN SECTION ===
          _buildSectionTitle(context, 'Giao diện', Icons.palette_outlined),
          const SizedBox(height: 12),
          _buildCard(
            context,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chế độ hiển thị',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeModeOption>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8FBFF),
                      selectedBackgroundColor: const Color(0xFF0066CC),
                      selectedForegroundColor: Colors.white,
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: ThemeModeOption.light,
                        icon: Icon(Icons.light_mode_outlined, size: 20),
                        label: Text('Sáng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      ButtonSegment(
                        value: ThemeModeOption.system,
                        icon: Icon(Icons.brightness_auto_outlined, size: 20),
                        label: Text('Hệ thống', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      ButtonSegment(
                        value: ThemeModeOption.dark,
                        icon: Icon(Icons.dark_mode_outlined, size: 20),
                        label: Text('Tối', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ],
                    selected: {themeProvider.currentThemeOption},
                    onSelectionChanged: (Set<ThemeModeOption> s) => themeProvider.setThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // === HỖ TRỢ & PHÁP LÝ SECTION ===
          _buildSectionTitle(context, 'Hỗ trợ & Pháp lý', Icons.support_agent_outlined),
          const SizedBox(height: 12),
          _buildCard(
            context,
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.feedback_outlined,
                  title: 'Gửi phản hồi / Báo lỗi',
                  iconColor: const Color(0xFF0066CC),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Điều khoản sử dụng',
                  iconColor: const Color(0xFF00B4D8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Chính sách quyền riêng tư',
                  iconColor: const Color(0xFF4CAF50),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'Giới thiệu',
                  iconColor: const Color(0xFFFF9800),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Widget xây dựng tiêu đề section với thanh màu bên trái
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
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
        Icon(icon, size: 24, color: const Color(0xFF0066CC)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // Widget xây dựng card với shadow
  Widget _buildCard(BuildContext context, {required Widget child}) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }

  // Widget xây dựng menu item
  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color iconColor,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget xây dựng divider
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 76),
      child: Container(
        height: 1,
        color: const Color(0xFFF0F0F0),
      ),
    );
  }
}