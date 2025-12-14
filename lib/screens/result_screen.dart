// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:app/services/api_service.dart';
// import 'package:app/screens/disease/disease_detail_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// // Các thư viện hỗ trợ chụp và chia sẻ
// import 'package:screenshot/screenshot.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';
//
// class ResultScreen extends StatefulWidget {
//   final Map<String, dynamic> diagnosisResult;
//
//   const ResultScreen({super.key, required this.diagnosisResult});
//
//   @override
//   State<ResultScreen> createState() => _ResultScreenState();
// }
//
// class _ResultScreenState extends State<ResultScreen> {
//   // 1. Controller để chụp màn hình
//   final ScreenshotController _screenshotController = ScreenshotController();
//
//   // 2. Biến trạng thái: Kiểm tra xem đang trong quá trình chia sẻ hay không
//   bool _isSharing = false;
//
//   // --- CÁC HÀM XỬ LÝ LOGIC ---
//
//   void _navigateToDetail() {
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
//           content: const Text('Chưa có thông tin chi tiết cho bệnh này trong hệ thống.'),
//           backgroundColor: Colors.orange,
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
//   // --- HÀM CHỤP VÀ CHIA SẺ (QUAN TRỌNG) ---
//   Future<void> _captureAndShare() async {
//     try {
//       // B1: Đặt trạng thái đang share -> UI sẽ ẩn nút, hiện footer
//       setState(() {
//         _isSharing = true;
//       });
//
//       // Chờ 100ms để Flutter kịp vẽ lại giao diện mới (ẩn nút)
//       await Future.delayed(const Duration(milliseconds: 100));
//
//       // B2: Thực hiện chụp ảnh widget
//       final Uint8List? imageBytes = await _screenshotController.capture();
//
//       // B3: Trả lại trạng thái bình thường ngay lập tức
//       setState(() {
//         _isSharing = false;
//       });
//
//       // B4: Lưu và Chia sẻ
//       if (imageBytes != null) {
//         final directory = await getTemporaryDirectory();
//         // Tạo tên file ngẫu nhiên hoặc cố định
//         final imagePath = await File('${directory.path}/checkmyhealth_result.png').create();
//         await imagePath.writeAsBytes(imageBytes);
//
//         // Mở dialog chia sẻ native
//         await Share.shareXFiles(
//           [XFile(imagePath.path)],
//           text: 'Kết quả chẩn đoán da liễu từ ứng dụng CheckMyHealth.',
//         );
//       }
//     } catch (e) {
//       // Nếu có lỗi, đảm bảo nút hiện lại
//       setState(() {
//         _isSharing = false;
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chia sẻ: $e')));
//       }
//     }
//   }
//
//   void _showMapOptions() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('Tìm cơ sở y tế gần bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
//     // Lấy dữ liệu an toàn
//     final String diseaseNameEn = widget.diagnosisResult['disease_name'] ?? 'Unknown';
//     final String diseaseNameVi = widget.diagnosisResult['disease_name_vi'] ?? 'Đang cập nhật';
//
//     final dynamic rawScore = widget.diagnosisResult['confidence_score'];
//     final double scoreVal = (rawScore is num) ? rawScore.toDouble() : 0.0;
//     final double confidence = scoreVal * 100;
//
//     final String description = widget.diagnosisResult['description'] ?? 'Không có mô tả.';
//     final String? imageUrl = widget.diagnosisResult['image_url'];
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FBFF),
//       appBar: AppBar(
//         title: const Text('Kết quả Chẩn đoán', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(colors: [Color(0xFF0066CC), Color(0xFF00B4D8)]),
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         // Nút share nhanh trên AppBar (vẫn giữ để tiện truy cập)
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.share_rounded),
//             onPressed: _captureAndShare,
//             tooltip: 'Chia sẻ kết quả',
//           )
//         ],
//       ),
//       body: SingleChildScrollView(
//         // Bao bọc toàn bộ nội dung cần chụp bằng Screenshot widget
//         child: Screenshot(
//           controller: _screenshotController,
//           child: Container(
//             color: const Color(0xFFF8FBFF), // Màu nền bắt buộc để ảnh không bị trong suốt
//             child: Column(
//               children: [
//                 // 1. Ảnh bệnh
//                 if (imageUrl != null)
//                   GestureDetector(
//                     onTap: () => _viewFullImage(imageUrl),
//                     child: Container(
//                       margin: const EdgeInsets.all(16),
//                       height: 250,
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
//                         image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
//                       ),
//                     ),
//                   ),
//
//                 // 2. Thẻ kết quả chính
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(colors: [Color(0xFF0066CC), Color(0xFF00B4D8)]),
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [BoxShadow(color: const Color(0xFF0066CC).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text('AI dự đoán bệnh:', style: TextStyle(color: Colors.white70, fontSize: 14)),
//                       const SizedBox(height: 8),
//                       // TÊN TIẾNG ANH
//                       Text(
//                         diseaseNameEn,
//                         style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
//                       ),
//                       const SizedBox(height: 4),
//                       // TÊN TIẾNG VIỆT
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(4)
//                         ),
//                         child: Text(
//                           diseaseNameVi,
//                           style: const TextStyle(fontSize: 16, color: Colors.white, fontStyle: FontStyle.italic),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         children: [
//                           const Icon(Icons.verified_user, color: Colors.white, size: 20),
//                           const SizedBox(width: 8),
//                           Text('Độ tin cậy: ${confidence.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // 3. Banner cảnh báo
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFFFF3E0),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.orange.withOpacity(0.5)),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
//                       const SizedBox(width: 12),
//                       const Expanded(
//                         child: Text(
//                           'Lưu ý: Kết quả AI chỉ mang tính tham khảo. Vui lòng đi khám bác sĩ để có kết luận chính xác.',
//                           style: TextStyle(color: Color(0xFFE65100), fontSize: 13, height: 1.4),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 // 4. Mô tả bệnh (Đưa lên trên các nút để khi chụp ảnh thông tin liền mạch hơn)
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   padding: const EdgeInsets.all(16),
//                   width: double.infinity,
//                   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("Mô tả sơ lược", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 8),
//                       Text(description, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 // -------------------------------------------------------------
//                 // LOGIC ẨN/HIỆN NÚT BẤM
//                 // -------------------------------------------------------------
//
//                 // Nếu KHÔNG phải đang share (_isSharing == false) thì hiện nút bấm
//                 if (!_isSharing) ...[
//                   // Nút Chia sẻ (Nút to)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: ElevatedButton.icon(
//                       onPressed: _captureAndShare,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.teal,
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         elevation: 0,
//                       ),
//                       icon: const Icon(Icons.share, color: Colors.white),
//                       label: const Text('Chia sẻ kết quả chẩn đoán', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   // Nút Xem chi tiết
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: ElevatedButton.icon(
//                       onPressed: _navigateToDetail,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF2196F3),
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         elevation: 0,
//                       ),
//                       icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
//                       label: const Text('Xem thông tin y khoa chi tiết', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   // Nút Tìm nơi chữa
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: ElevatedButton.icon(
//                       onPressed: _showMapOptions,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: const Color(0xFF0066CC),
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           side: const BorderSide(color: Color(0xFF0066CC)),
//                         ),
//                         elevation: 0,
//                       ),
//                       icon: const Icon(Icons.map_rounded),
//                       label: const Text('Tìm nơi điều trị gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                 ],
//
//                 // Nếu ĐANG share (_isSharing == true) thì hiện Footer Watermark
//                 if (_isSharing)
//                   Container(
//                     margin: const EdgeInsets.only(top: 20),
//                     padding: const EdgeInsets.all(10),
//                     alignment: Alignment.center,
//                     child: Column(
//                       children: [
//                         const Divider(),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: const [
//                             Icon(Icons.health_and_safety, color: Colors.grey, size: 16),
//                             SizedBox(width: 8),
//                             Text(
//                               "Chẩn đoán bởi CheckMyHealth AI",
//                               style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         const Text(
//                           "Tải ứng dụng để bảo vệ sức khỏe da liễu của bạn.",
//                           style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
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

// Các thư viện hỗ trợ chụp và chia sẻ
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> diagnosisResult;

  const ResultScreen({super.key, required this.diagnosisResult});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  // --- LOGIC MÀU SẮC THEO MỨC ĐỘ NGUY HIỂM ---
  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'critical':
      case 'high':
        return const Color(0xFFD32F2F); // Đỏ đậm
      case 'moderate':
        return const Color(0xFFF57C00); // Cam
      case 'low':
      case 'none': // Da khỏe mạnh
        return const Color(0xFF388E3C); // Xanh lá
      default:
        return const Color(0xFF0066CC); // Xanh dương (Mặc định)
    }
  }

  String _getRiskText(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'critical': return 'RẤT NGUY HIỂM';
      case 'high': return 'NGUY CƠ CAO';
      case 'moderate': return 'TRUNG BÌNH';
      case 'low': return 'LÀNH TÍNH';
      case 'none': return 'AN TOÀN';
      default: return 'CHƯA XÁC ĐỊNH';
    }
  }

  // --- CÁC HÀM XỬ LÝ LOGIC ---

  void _navigateToDetail() {
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
          content: const Text('Bệnh lý này chưa có bài viết chi tiết hoặc là da lành tính.'),
          backgroundColor: Colors.grey,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _openMapSearch(String query) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
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
              child: Image.network(imageUrl),
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

  void _showMapOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tìm cơ sở y tế gần bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  // --- GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    // 1. Lấy dữ liệu từ Backend mới
    final String diseaseNameEn = widget.diagnosisResult['disease_name'] ?? 'Unknown';
    final String diseaseNameVi = widget.diagnosisResult['disease_name_vi'] ?? 'Kết quả chẩn đoán';

    // 2. Các trường mới từ AI
    final String riskLevel = widget.diagnosisResult['risk_level'] ?? 'unknown';
    final String recommendation = widget.diagnosisResult['recommendation'] ?? 'Vui lòng tham khảo ý kiến bác sĩ.';

    // 3. Xử lý logic hiển thị
    final dynamic rawScore = widget.diagnosisResult['confidence_score'];
    final double confidence = (rawScore is num) ? rawScore.toDouble() * 100 : 0.0;

    final String description = widget.diagnosisResult['description'] ?? '';
    final String? imageUrl = widget.diagnosisResult['image_url'];

    // 4. Xác định màu chủ đạo
    final Color themeColor = _getRiskColor(riskLevel);
    final bool isHealthy = riskLevel == 'none' || diseaseNameEn == 'Normal Skin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text('Kết quả Phân tích', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: themeColor, // Đổi màu AppBar theo mức độ nguy hiểm
        elevation: 0,
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
            color: const Color(0xFFF8FBFF),
            child: Column(
              children: [
                // 1. Ảnh
                if (imageUrl != null)
                  GestureDetector(
                    onTap: () => _viewFullImage(imageUrl),
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2. Thẻ kết quả chính (Card đè lên ảnh một chút nếu muốn, hoặc để dưới)
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Badge Mức độ nguy hiểm
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: themeColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            _getRiskText(riskLevel),
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tên bệnh (Việt)
                        Text(
                          diseaseNameVi,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Tên bệnh (Anh)
                        Text(
                          diseaseNameEn,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Độ tin cậy AI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined, size: 20, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Độ tin cậy AI: ${confidence.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 15, color: Colors.grey[800], fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Khuyến nghị (Recommendation) - MỚI
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHealthy ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHealthy ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isHealthy ? Icons.check_circle_outline : Icons.info_outline,
                        color: isHealthy ? Colors.green[700] : Colors.orange[800],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lời khuyên",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isHealthy ? Colors.green[800] : Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recommendation,
                              style: TextStyle(
                                color: isHealthy ? Colors.green[900] : Colors.orange[900],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Mô tả chi tiết (nếu có)
                if (description.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Thông tin y khoa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.6),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                // 5. Nút bấm (Ẩn khi share)
                if (!_isSharing) ...[
                  // Nút Xem chi tiết (Chỉ hiện nếu không phải Normal Skin)
                  if (!isHealthy && widget.diagnosisResult['info_id'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ElevatedButton.icon(
                        onPressed: _navigateToDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: themeColor.withOpacity(0.4),
                        ),
                        icon: const Icon(Icons.article_outlined),
                        label: const Text('Xem bài viết chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  // Nút Tìm bác sĩ (Chỉ hiện nếu có nguy cơ)
                  if (!isHealthy)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: OutlinedButton.icon(
                        onPressed: _showMapOptions,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeColor,
                          side: BorderSide(color: themeColor),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.location_on_outlined),
                        label: const Text('Tìm cơ sở y tế gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  // Nút quay lại
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Chụp ảnh khác", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ),
                ],

                // Footer khi share
                if (_isSharing)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified_outlined, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("Phân tích bởi CheckMyHealth AI", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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