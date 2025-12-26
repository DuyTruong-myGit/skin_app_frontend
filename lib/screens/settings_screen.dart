import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';

// Import các trang (Giữ nguyên logic import)
import 'package:app/screens/static/about_screen.dart';
import 'package:app/screens/static/privacy_screen.dart';
import 'package:app/screens/static/terms_screen.dart';
import 'package:app/screens/profile_screen.dart';
import 'package:app/screens/static/feedback_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Logic giữ nguyên
    final apiService = ApiService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Màu nền chuẩn Home
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // === TÀI KHOẢN SECTION ===
            _buildSectionHeader('Tài khoản'),
            const SizedBox(height: 12),
            _buildSettingItem(
              context,
              title: 'Hồ sơ cá nhân',
              desc: 'Thay đổi tên, ảnh đại diện',
              icon: Icons.person_outline,
              color: Colors.blue, // Theme Blue
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),

            const SizedBox(height: 24),

            // === HỖ TRỢ & PHÁP LÝ SECTION ===
            _buildSectionHeader('Hỗ trợ & Pháp lý'),
            const SizedBox(height: 12),

            _buildSettingItem(
              context,
              title: 'Gửi phản hồi / Báo lỗi',
              desc: 'Đóng góp ý kiến cho ứng dụng',
              icon: Icons.feedback_outlined,
              color: Colors.purple, // Theme Purple
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                );
              },
            ),
            const SizedBox(height: 10), // Gap giữa các item giống Categories

            _buildSettingItem(
              context,
              title: 'Điều khoản sử dụng',
              desc: 'Quy định sử dụng dịch vụ',
              icon: Icons.description_outlined,
              color: Colors.orange, // Theme Orange
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildSettingItem(
              context,
              title: 'Chính sách quyền riêng tư',
              desc: 'Cam kết bảo mật thông tin',
              icon: Icons.privacy_tip_outlined,
              color: Colors.green, // Theme Green
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildSettingItem(
              context,
              title: 'Giới thiệu',
              desc: 'Phiên bản v1.0.0',
              icon: Icons.info_outline,
              color: Colors.grey, // Theme Grey
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),

            const SizedBox(height: 40),

            // Footer nhỏ (Optional - Style giống footer Home)
            Text(
              'Health Assistant App © 2024',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  // Header giống "Dịch vụ chuyên khoa" / "Chỉ số sức khỏe"
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(), // Có thể để Upper hoặc Normal tùy thích, Home dùng Normal nhưng đậm
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // Item giống "Categories" (Chẩn đoán, Lịch sử...)
  Widget _buildSettingItem(
      BuildContext context, {
        required String title,
        required String desc,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
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
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Icon Box style chuẩn Home Screen (QuickActions/Categories)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), // shade50 simulation
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)), // border shade200 simulation
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color, // shade700 logic (thường dùng base color đậm hơn chút)
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}