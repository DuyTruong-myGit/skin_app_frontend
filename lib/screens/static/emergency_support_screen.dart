import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencySupportScreen extends StatelessWidget {
  const EmergencySupportScreen({super.key});

  // Hàm gọi điện thoại
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (!await launchUrl(launchUri)) {
        throw 'Không thể thực hiện cuộc gọi';
      }
    } catch (e) {
      debugPrint("Lỗi gọi điện: $e");
    }
  }
// Hàm hỗ trợ mã hóa để tránh lỗi dấu cộng (+) thay vì dấu cách
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
  // Hàm gửi email
  Future<void> _sendEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      // SỬA Ở ĐÂY: Dùng hàm encode riêng cho phần query
      query: _encodeQueryParameters({
        'subject': 'Hỗ trợ khẩn cấp - CheckMyHealth App',
        'body': 'Xin chào, tôi cần hỗ trợ về vấn đề...'
      }),
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw 'Không thể mở ứng dụng Email';
      }
    } catch (e) {
      debugPrint("Lỗi gửi mail: $e");
    }
  }

  // Hàm mở bản đồ tìm kiếm
  Future<void> _openMapSearch(String query) async {
    // URL chuẩn để mở Google Maps tìm kiếm
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Không thể mở bản đồ';
      }
    } catch (e) {
      debugPrint("Lỗi mở map: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Hỗ trợ Khẩn cấp", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Phần liên hệ hệ thống
            const Text(
              "Liên hệ Hệ thống",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.headset_mic_rounded,
              title: "Tổng đài hỗ trợ",
              subtitle: "1900 1234 (8:00 - 22:00)",
              color: Colors.blue,
              onTap: () => _makePhoneCall("19001234"),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: "Email hỗ trợ",
              subtitle: "support@checkmyhealth.com",
              color: Colors.orange,
              onTap: () => _sendEmail("support@checkmyhealth.com"),
            ),

            const SizedBox(height: 30),

            // 2. Số khẩn cấp quốc gia (Rất quan trọng)
            const Text(
              "Số khẩn cấp Quốc gia",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEmergencyButton(
                    number: "115",
                    label: "Cấp cứu",
                    color: Colors.red,
                    onTap: () => _makePhoneCall("115"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEmergencyButton(
                    number: "111",
                    label: "BVTE", // Bảo vệ trẻ em
                    color: Colors.green,
                    onTap: () => _makePhoneCall("111"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 3. Tìm kiếm cơ sở y tế gần nhất
            const Text(
              "Cơ sở y tế quanh đây",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              "Mở Google Maps để tìm địa điểm gần vị trí của bạn nhất.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            _buildMapOption(
              icon: Icons.local_hospital_rounded,
              title: "Tìm Bệnh viện gần nhất",
              color: Colors.red,
              onTap: () => _openMapSearch("Bệnh viện gần đây"),
            ),
            const SizedBox(height: 12),
            _buildMapOption(
              icon: Icons.local_pharmacy_rounded,
              title: "Tìm Nhà thuốc gần nhất",
              color: Colors.green,
              onTap: () => _openMapSearch("Nhà thuốc gần đây"),
            ),
            const SizedBox(height: 12),
            _buildMapOption(
              icon: Icons.health_and_safety_rounded,
              title: "Tìm Phòng khám Da liễu",
              color: Colors.blue,
              onTap: () => _openMapSearch("Phòng khám da liễu gần đây"),
            ),
          ],
        ),
      ),
    );
  }

  // Widget thẻ liên hệ
  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Widget nút số khẩn cấp
  Widget _buildEmergencyButton({
    required String number,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Column(
        children: [
          Text(number, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Widget nút mở bản đồ
  Widget _buildMapOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.map_outlined, size: 20, color: Colors.blue),
      ),
    );
  }
}