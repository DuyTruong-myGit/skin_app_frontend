// import 'dart:io';
// import 'dart:typed_data';
// import 'package:app/screens/disease/disease_detail_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:screenshot/screenshot.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:app/screens/safety_check_screen.dart';
// class ResultScreen extends StatefulWidget {
//   final Map<String, dynamic> diagnosisResult;
//   final String? imageUrl; // Đã thêm tham số này để nhận ảnh từ History
//
//   const ResultScreen({
//     super.key,
//     required this.diagnosisResult,
//     this.imageUrl,
//   });
//
//   @override
//   State<ResultScreen> createState() => _ResultScreenState();
// }
//
// class _ResultScreenState extends State<ResultScreen> {
//   final ScreenshotController _screenshotController = ScreenshotController();
//   bool _isSharing = false;
//
//   // --- 1. LOGIC CHỌN MÀU THEO MỨC ĐỘ NGUY HIỂM ---
//   // Đã cập nhật: Thêm case 'medium' để xử lý đồng bộ dữ liệu cũ/mới
//   Color _getThemeColor(String? riskLevel) {
//     switch (riskLevel?.toLowerCase()) {
//       case 'critical':
//       case 'high':
//         return const Color(0xFFD32F2F); // Đỏ đậm (Nguy hiểm)
//       case 'moderate':
//       case 'medium': // <--- ĐÃ THÊM: Fix lỗi hiển thị màu xám khi backend trả về 'medium'
//         return const Color(0xFFF57C00); // Cam (Cảnh báo)
//       case 'low':
//       case 'none':
//         return const Color(0xFF388E3C); // Xanh lá (Lành tính)
//       default:
//         return const Color(0xFF607D8B); // Xám xanh (Không xác định - Neutral)
//     }
//   }
//
//   String _getRiskText(String? riskLevel) {
//     switch (riskLevel?.toLowerCase()) {
//       case 'critical': return 'RẤT NGUY HIỂM';
//       case 'high': return 'NGUY CƠ CAO';
//       case 'moderate':
//       case 'medium': return 'CẦN THEO DÕI'; // <--- ĐÃ THÊM: Fix lỗi hiển thị text "Chưa rõ mức độ"
//       case 'low': return 'LÀNH TÍNH';
//       case 'none': return 'DA KHỎE MẠNH';
//       default: return 'CHƯA RÕ MỨC ĐỘ';
//     }
//   }
//
//   // --- CÁC HÀM XỬ LÝ LOGIC ---
//
//   void _navigateToDetail(Color themeColor) {
//     final int? infoId = widget.diagnosisResult['info_id'];
//     final String diseaseNameVi = widget.diagnosisResult['disease_name_vi'] ?? 'Chi tiết bệnh';
//
//     if (infoId != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => DiseaseDetailScreen(
//             diseaseId: infoId,
//             diseaseName: diseaseNameVi,
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Hiện chưa có bài viết chi tiết cho tình trạng này.'),
//           backgroundColor: themeColor,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         ),
//       );
//     }
//   }
//
//   Future<void> _openMapSearch(String query) async {
//     final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
//     try {
//       if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
//         throw 'Không thể mở bản đồ';
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
//       }
//     }
//   }
//
//   void _viewFullImage(String imageUrl) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.black,
//         insetPadding: EdgeInsets.zero,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             InteractiveViewer(
//               panEnabled: true,
//               minScale: 0.5,
//               maxScale: 4.0,
//               child: Image.network(imageUrl),
//             ),
//             Positioned(
//               top: 40,
//               right: 20,
//               child: IconButton(
//                 icon: const Icon(Icons.close, color: Colors.white, size: 30),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _captureAndShare() async {
//     try {
//       setState(() => _isSharing = true);
//       await Future.delayed(const Duration(milliseconds: 100));
//       final Uint8List? imageBytes = await _screenshotController.capture();
//       setState(() => _isSharing = false);
//
//       if (imageBytes != null) {
//         final directory = await getTemporaryDirectory();
//         final imagePath = await File('${directory.path}/checkmyhealth_result.png').create();
//         await imagePath.writeAsBytes(imageBytes);
//
//         await Share.shareXFiles(
//           [XFile(imagePath.path)],
//           text: 'Kết quả chẩn đoán da liễu từ ứng dụng CheckMyHealth.',
//         );
//       }
//     } catch (e) {
//       setState(() => _isSharing = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chia sẻ: $e')));
//       }
//     }
//   }
//
//   void _showMapOptions(Color themeColor) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Tìm cơ sở y tế gần bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: const Icon(Icons.local_pharmacy, color: Colors.green, size: 30),
//               title: const Text('Tìm Nhà thuốc gần nhất'),
//               onTap: () { Navigator.pop(context); _openMapSearch('Nhà thuốc'); },
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.local_hospital, color: Colors.red, size: 30),
//               title: const Text('Tìm Phòng khám Da liễu'),
//               onTap: () { Navigator.pop(context); _openMapSearch('Bệnh viện da liễu'); },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // --- GIAO DIỆN ---
//   @override
//   Widget build(BuildContext context) {
//     final String diseaseNameEn = widget.diagnosisResult['disease_name'] ?? 'Unknown';
//     final String diseaseNameVi = widget.diagnosisResult['disease_name_vi'] ?? 'Kết quả chẩn đoán';
//     final String riskLevel = widget.diagnosisResult['risk_level'] ?? 'unknown';
//
//     // --- ĐÃ SỬA: Gán cứng lời khuyên theo yêu cầu ---
//     const String recommendation = 'Vui lòng tham khảo ý kiến bác sĩ chuyên khoa da liễu để được chẩn đoán chính xác.';
//
//     final dynamic rawScore = widget.diagnosisResult['confidence_score'];
//     final double confidence = (rawScore is num) ? rawScore.toDouble() * 100 : 0.0;
//
//     final String description = widget.diagnosisResult['description'] ?? '';
//     final String? imageUrl = widget.imageUrl ?? widget.diagnosisResult['image_url'];
//
//     // 2. Lấy màu chủ đạo dựa trên bệnh
//     final Color themeColor = _getThemeColor(riskLevel);
//
//     // Check xem có phải da lành tính không
//     final bool isHealthy = riskLevel == 'none' || diseaseNameEn == 'Normal Skin' || riskLevel == 'low';
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFFAFAFA), // Nền xám rất nhạt (Trung tính)
//       appBar: AppBar(
//         title: const Text('Kết quả Phân tích', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         backgroundColor: themeColor, // AppBar đổi màu theo bệnh
//         elevation: 0,
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.share_rounded),
//             onPressed: _captureAndShare,
//             tooltip: 'Chia sẻ',
//           )
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Screenshot(
//           controller: _screenshotController,
//           child: Container(
//             color: const Color(0xFFFAFAFA),
//             child: Column(
//               children: [
//                 // 1. Phần Ảnh (Header)
//                 if (imageUrl != null)
//                   GestureDetector(
//                     onTap: () => _viewFullImage(imageUrl),
//                     child: Stack(
//                       children: [
//                         Container(
//                           height: 240,
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             color: Colors.black12,
//                             image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
//                           ),
//                         ),
//                         // Lớp phủ mờ bên dưới để bo góc nối với phần dưới
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           child: Container(
//                             height: 30,
//                             decoration: const BoxDecoration(
//                               color: Color(0xFFFAFAFA),
//                               borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                 // 2. Thẻ kết quả chính
//                 Transform.translate(
//                   offset: const Offset(0, -20), // Đẩy lên chèn vào ảnh 1 chút
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 20),
//                     padding: const EdgeInsets.all(24),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(24),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.08),
//                           blurRadius: 20,
//                           offset: const Offset(0, 10),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         // Badge Mức độ
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                           decoration: BoxDecoration(
//                             color: themeColor.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             _getRiskText(riskLevel),
//                             style: TextStyle(
//                               color: themeColor,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 13,
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Tên bệnh
//                         Text(
//                           diseaseNameVi,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey[900], // Màu đen xám, không dùng xanh
//                             height: 1.2,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           diseaseNameEn,
//                           style: TextStyle(fontSize: 15, color: Colors.grey[600], fontStyle: FontStyle.italic),
//                         ),
//
//                         const SizedBox(height: 24),
//                         const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
//                         const SizedBox(height: 16),
//
//                         // Độ tin cậy (Dùng thanh Progress thay vì vòng tròn xanh cũ)
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Độ tin cậy AI',
//                                     style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(4),
//                                     child: LinearProgressIndicator(
//                                       value: confidence / 100,
//                                       minHeight: 8,
//                                       backgroundColor: Colors.grey[200],
//                                       valueColor: AlwaysStoppedAnimation<Color>(themeColor),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             Text(
//                               '${confidence.toStringAsFixed(1)}%',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: themeColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // 3. Khuyến nghị (Recommendation)
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 20),
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: themeColor.withOpacity(0.08), // Nền nhạt theo màu chủ đạo
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: themeColor.withOpacity(0.2)),
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.info_outline_rounded, color: themeColor, size: 24),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Lời khuyên",
//                               style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               recommendation,
//                               style: TextStyle(color: Colors.grey[800], height: 1.4),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // 4. Mô tả chi tiết
//                 if (description.isNotEmpty)
//                   Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 20),
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: Colors.grey[200]!),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.description_outlined, size: 20, color: Colors.grey[700]),
//                             const SizedBox(width: 8),
//                             const Text("Thông tin y khoa", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           description,
//                           style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.6),
//                           textAlign: TextAlign.justify,
//                         ),
//                       ],
//                     ),
//                   ),
//
//                 if (widget.diagnosisResult['top3_predictions'] != null)
//                   Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: Colors.grey[200]!),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.analytics_outlined, size: 20, color: Colors.grey[700]),
//                             const SizedBox(width: 8),
//                             const Text("Top 3 Chẩn đoán", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         ...List.generate(
//                           (widget.diagnosisResult['top3_predictions'] as List).length,
//                               (index) {
//                             final pred = widget.diagnosisResult['top3_predictions'][index];
//                             final confidence = (pred['confidence'] * 100).toStringAsFixed(1);
//                             return Padding(
//                               padding: const EdgeInsets.only(bottom: 8),
//                               child: Row(
//                                 children: [
//                                   Container(
//                                     width: 24,
//                                     height: 24,
//                                     decoration: BoxDecoration(
//                                       color: index == 0 ? themeColor : Colors.grey[300],
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: Center(
//                                       child: Text(
//                                         '${index + 1}',
//                                         style: TextStyle(
//                                           color: index == 0 ? Colors.white : Colors.black,
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Text(
//                                       pred['class'],
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
//                                       ),
//                                     ),
//                                   ),
//                                   Text(
//                                     '$confidence%',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color: themeColor,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//
//                 const SizedBox(height: 30),
//
//                 // 5. Nút chức năng
//                 if (!_isSharing) ...[
//                   // Nút Xem chi tiết
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const SafetyCheckScreen()),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white, // Nền trắng
//                         foregroundColor: const Color(0xFFD32F2F), // Chữ đỏ
//                         side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5), // Viền đỏ
//                         minimumSize: const Size(double.infinity, 52),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         elevation: 0,
//                       ),
//                       icon: const Icon(Icons.security_rounded),
//                       label: const Text(
//                         'Kiểm tra dấu hiệu nguy hiểm',
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//
//                   if (!isHealthy && widget.diagnosisResult['info_id'] != null)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//                       child: ElevatedButton.icon(
//                         onPressed: () => _navigateToDetail(themeColor),
//                         style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
//                         icon: const Icon(Icons.article_rounded),
//                         label: const Text('Xem bài viết chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                       ),
//                     ),
//
//                   if (!isHealthy)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//                       child: OutlinedButton.icon(
//                         onPressed: () => _showMapOptions(themeColor),
//                         style: OutlinedButton.styleFrom(foregroundColor: themeColor, side: BorderSide(color: themeColor), minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//                         icon: const Icon(Icons.location_on_outlined),
//                         label: const Text('Tìm cơ sở y tế gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                       ),
//                     ),
//
//                   // Nút Quay lại
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//                     child: TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: Text("Quay lại", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
//                     ),
//                   ),
//                 ],
//
//                 // Footer khi share
//                 if (_isSharing)
//                   Padding(
//                     padding: const EdgeInsets.all(24),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.verified_user_outlined, size: 16, color: Colors.grey[500]),
//                         const SizedBox(width: 8),
//                         Text(
//                             "CheckMyHealth AI Diagnosis",
//                             style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 12)
//                         ),
//                       ],
//                     ),
//                   ),
//
//                 const SizedBox(height: 40),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'dart:typed_data';
import 'package:app/screens/disease/disease_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app/screens/safety_check_screen.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> diagnosisResult;
  final String? imageUrl;

  const ResultScreen({
    super.key,
    required this.diagnosisResult,
    this.imageUrl,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Color _getThemeColor(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'critical':
      case 'high':
        return const Color(0xFFD32F2F);
      case 'moderate':
      case 'medium':
        return const Color(0xFFF57C00);
      case 'low':
      case 'none':
        return const Color(0xFF388E3C);
      default:
        return const Color(0xFF607D8B);
    }
  }

  String _getRiskText(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'critical': return 'RẤT NGUY HIỂM';
      case 'high': return 'NGUY CƠ CAO';
      case 'moderate':
      case 'medium': return 'CẦN THEO DÕI';
      case 'low': return 'LÀNH TÍNH';
      case 'none': return 'DA KHỎE MẠNH';
      default: return 'CHƯA RÕ MỨC ĐỘ';
    }
  }

  void _navigateToDetail(Color themeColor) {
    final int? infoId = widget.diagnosisResult['info_id'];
    final String diseaseNameVi = widget.diagnosisResult['disease_name_vi'] ?? 'Chi tiết bệnh';

    if (infoId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiseaseDetailScreen(
            diseaseId: infoId,
            diseaseName: diseaseNameVi,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hiện chưa có bài viết chi tiết cho tình trạng này.'),
          backgroundColor: themeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _openMapSearch(String query) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/$query');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Không thể mở bản đồ';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _viewFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              // SỬA LỖI HIỂN THỊ ẢNH Ở ĐÂY
              child: _buildImageWidget(imageUrl),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HÀM HELPER ĐỂ XỬ LÝ ẢNH NETWORK VS LOCAL
  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return NetworkImage(imageUrl);
    } else {
      return FileImage(File(imageUrl));
    }
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return Image.network(imageUrl);
    } else {
      return Image.file(File(imageUrl));
    }
  }

  Future<void> _captureAndShare() async {
    try {
      setState(() => _isSharing = true);
      await Future.delayed(const Duration(milliseconds: 100));
      final Uint8List? imageBytes = await _screenshotController.capture();
      setState(() => _isSharing = false);

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/checkmyhealth_result.png').create();
        await imagePath.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Kết quả chẩn đoán da liễu từ ứng dụng CheckMyHealth.',
        );
      }
    } catch (e) {
      setState(() => _isSharing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chia sẻ: $e')));
      }
    }
  }

  void _showMapOptions(Color themeColor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tìm cơ sở y tế gần bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.local_pharmacy, color: Colors.green, size: 30),
              title: const Text('Tìm Nhà thuốc gần nhất'),
              onTap: () { Navigator.pop(context); _openMapSearch('Nhà thuốc'); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red, size: 30),
              title: const Text('Tìm Phòng khám Da liễu'),
              onTap: () { Navigator.pop(context); _openMapSearch('Bệnh viện da liễu'); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String diseaseNameEn = widget.diagnosisResult['disease_name'] ?? 'Unknown';
    final String diseaseNameVi = widget.diagnosisResult['disease_name_vi'] ?? 'Kết quả chẩn đoán';
    final String riskLevel = widget.diagnosisResult['risk_level'] ?? 'unknown';
    const String recommendation = 'Vui lòng tham khảo ý kiến bác sĩ chuyên khoa da liễu để được chẩn đoán chính xác.';

    final dynamic rawScore = widget.diagnosisResult['confidence_score'];
    final double confidence = (rawScore is num) ? rawScore.toDouble() * 100 : 0.0;

    final String description = widget.diagnosisResult['description'] ?? '';
    // Ưu tiên lấy ảnh từ widget params, nếu không có thì lấy từ result json
    final String? imageUrl = widget.imageUrl ?? widget.diagnosisResult['image_url'];

    final Color themeColor = _getThemeColor(riskLevel);
    final bool isHealthy = riskLevel == 'none' || diseaseNameEn == 'Normal Skin' || riskLevel == 'low';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Kết quả Phân tích', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _captureAndShare,
            tooltip: 'Chia sẻ',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Screenshot(
          controller: _screenshotController,
          child: Container(
            color: const Color(0xFFFAFAFA),
            child: Column(
              children: [
                // 1. Phần Ảnh (Header) - ĐÃ SỬA LOGIC HIỂN THỊ
                if (imageUrl != null && imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _viewFullImage(imageUrl),
                    child: Stack(
                      children: [
                        Container(
                          height: 240,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            image: DecorationImage(
                              // SỬA Ở ĐÂY: Check Online vs Offline
                              image: _getImageProvider(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Thẻ kết quả chính
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRiskText(riskLevel),
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          diseaseNameVi,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diseaseNameEn,
                          style: TextStyle(fontSize: 15, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Độ tin cậy AI',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: confidence / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${confidence.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Khuyến nghị
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: themeColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: themeColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lời khuyên",
                              style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recommendation,
                              style: TextStyle(color: Colors.grey[800], height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Mô tả chi tiết
                if (description.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_outlined, size: 20, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            const Text("Thông tin y khoa", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.6),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                // 5. Nút chức năng
                if (!_isSharing) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SafetyCheckScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.security_rounded),
                      label: const Text(
                        'Kiểm tra dấu hiệu nguy hiểm',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  if (!isHealthy && widget.diagnosisResult['info_id'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToDetail(themeColor),
                        style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        icon: const Icon(Icons.article_rounded),
                        label: const Text('Xem bài viết chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),

                  if (!isHealthy)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: OutlinedButton.icon(
                        onPressed: () => _showMapOptions(themeColor),
                        style: OutlinedButton.styleFrom(foregroundColor: themeColor, side: BorderSide(color: themeColor), minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.location_on_outlined),
                        label: const Text('Tìm cơ sở y tế gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Quay lại", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                    ),
                  ),
                ],

                if (_isSharing)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                            "CheckMyHealth AI Diagnosis",
                            style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}