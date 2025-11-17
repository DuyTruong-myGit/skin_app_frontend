// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:app/services/api_service.dart';
// import 'package:app/screens/result_screen.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:app/config/app_theme.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'dart:io';
// import 'package:app/providers/profile_provider.dart';
// import 'package:provider/provider.dart';
// class HomeScreen extends StatefulWidget {
//   final Function(int) onTabChange;
//   const HomeScreen({super.key, required this.onTabChange});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final ApiService _apiService = ApiService();
//   final ImagePicker _picker = ImagePicker();
//
//   late Future<Map<String, dynamic>> _profileFuture;
//   late Future<List<Map<String, dynamic>>> _newsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }
//
//   void _loadData() {
//     _profileFuture = _apiService.getProfile();
//     _newsFuture = _loadNews();
//   }
//
//   Future<void> _handleRefresh() async {
//     // Yêu cầu provider tải lại
//     await context.read<ProfileProvider>().loadProfile();
//     // Vẫn tải lại tin tức
//     setState(() {
//       _newsFuture = _loadNews();
//     });
//   }
//   Future<List<Map<String, dynamic>>> _loadNews() async {
//     try {
//       final connectivityResult = await Connectivity().checkConnectivity();
//       final hasConnection = connectivityResult.contains(ConnectivityResult.wifi) ||
//           connectivityResult.contains(ConnectivityResult.mobile);
//
//       if (!hasConnection) {
//         return []; // Trả về rỗng nếu không có mạng
//       }
//       try {
//         final result = await InternetAddress.lookup('google.com');
//         if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
//           // Có internet thực → tiếp tục gọi API
//         } else {
//           return [];
//         }
//       } catch (_) {
//         return [];
//       }
//       final sources = await _apiService.getNewsSources();
//       if (sources.isEmpty) return [];
//
//       final vnExpress = sources.firstWhere(
//             (s) => s['url'].toString().contains('vnexpress'),
//         orElse: () => sources.first,
//       );
//
//       return await _apiService.scrapeNews(vnExpress['url']);
//     } catch (e) {
//       print("Lỗi tải tin tức: $e");
//       return [];
//     }
//   }
//   // === THÊM HÀM MỚI: CẮT ẢNH ===
//   Future<XFile?> _cropImage(XFile imageFile) async {
//     final croppedFile = await ImageCropper().cropImage(
//       sourcePath: imageFile.path,
//       // Cấu hình giao diện cắt ảnh
//       uiSettings: [
//         AndroidUiSettings(
//           toolbarTitle: 'Cắt & Xoay ảnh',
//           toolbarColor: AppTheme.primaryColor,
//           toolbarWidgetColor: Colors.white,
//           initAspectRatio: CropAspectRatioPreset.square,
//           lockAspectRatio: false,
//         ),
//         IOSUiSettings(
//           title: 'Cắt & Xoay ảnh',
//         ),
//       ],
//     );
//     // Trả về file đã cắt (hoặc null nếu user hủy)
//     return croppedFile == null ? null : XFile(croppedFile.path);
//   }
//
//   // === SỬA LOGIC HIỂN THỊ LOADING ===
//   Future<void> _startDiagnosis() async {
//     // 1. Chọn nguồn ảnh
//     final source = await showDialog<ImageSource>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Chọn nguồn ảnh'),
//         actions: [
//           TextButton(
//             child: const Text('Máy ảnh'),
//             onPressed: () => Navigator.pop(context, ImageSource.camera),
//           ),
//           TextButton(
//             child: const Text('Thư viện'),
//             onPressed: () => Navigator.pop(context, ImageSource.gallery),
//           ),
//         ],
//       ),
//     );
//     if (source == null) return;
//
//     // 2. Lấy ảnh
//     final XFile? originalImage = await _picker.pickImage(source: source);
//     if (originalImage == null) return;
//
//     // 3. Cắt ảnh
//     final XFile? croppedImage = await _cropImage(originalImage);
//     if (croppedImage == null) return;
//
//     // 4. Hiển thị Dialog Loading
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return const AlertDialog(
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text("Đang phân tích hình ảnh..."),
//             ],
//           ),
//         );
//       },
//     );
//
//     // 5. GỌI API
//     try {
//       final result = await _apiService.diagnose(croppedImage);
//
//       if (!mounted) return;
//       Navigator.pop(context); // Tắt Dialog Loading
//
//       // 6. Chuyển sang Màn hình Kết quả
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ResultScreen(diagnosisResult: result),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       Navigator.pop(context); // Tắt Dialog Loading
//
//       // 7. Hiển thị lỗi
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//   // =================================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         toolbarHeight: 80,
//         title: _buildHeader(), // <-- GỌI HÀM ĐÃ SỬA
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         elevation: 0,
//       ),
//       body: RefreshIndicator(
//         onRefresh: _handleRefresh,
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildNewsSection(),
//               _buildCategorySection(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     // Dùng Consumer để tự động cập nhật khi provider thay đổi
//     return Consumer<ProfileProvider>(
//       builder: (context, profileProvider, child) {
//         String displayName = '...';
//         String? avatarUrl;
//
//         if (profileProvider.isLoading && profileProvider.profileData == null) {
//           displayName = 'Đang tải...';
//         } else if (profileProvider.profileData != null) {
//           displayName = profileProvider.profileData?['fullName'] ?? 'Người dùng';
//           avatarUrl = profileProvider.profileData?['avatar_url'];
//         } else {
//           displayName = 'Khách'; // Nếu tải lỗi
//         }
//
//         // 3. ĐANG TẢI (ConnectionState.waiting)
//         // (Không cần làm gì, nó sẽ giữ giá trị mặc định '...')
//
//         // 4. Trả về giao diện (luôn an toàn)
//         return Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Xin chào,',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//                 Text(
//                   displayName,
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//
//             // === SỬA LOGIC AVATAR ===
//             // Chỉ truyền backgroundImage nếu nó KHÔNG null
//             CircleAvatar(
//               radius: 24,
//               backgroundImage: (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
//               onBackgroundImageError: (avatarUrl != null) ? (exception, stackTrace) {
//                 print("Lỗi tải Avatar: $exception");
//               } : null,
//               child: (avatarUrl == null) ? const Icon(Icons.person, size: 24) : null,
//             ),
//             // ========================
//           ],
//         );
//       },
//     );
//   }
//
//   // === SỬA LỖI TRONG FUTUREBUILDER CỦA TIN TỨC ===
//   // Bảng tin (News Carousel)
//   Widget _buildNewsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//           child: Text(
//             'Tin tức Sức khỏe',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//         ),
//         SizedBox(
//           height: 220, // Chiều cao của carousel
//           child: FutureBuilder<List<Map<String, dynamic>>>(
//             future: _newsFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//
//               // === SỬA LỖI CRASH (Null check) TẠI ĐÂY ===
//               if (snapshot.hasError) {
//                 return const Center(child: Text('Lỗi tải tin tức.'));
//               }
//               if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
//                 return const Center(child: Text('Không tải được tin tức.'));
//               }
//               // ======================================
//
//               final articles = snapshot.data!;
//               return ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: articles.length,
//                 itemBuilder: (context, index) {
//                   final article = articles[index];
//                   if (article['image'] == null) return const SizedBox.shrink();
//
//                   return _buildNewsCard(
//                       article['image']!,
//                       article['title'] ?? 'Không có tiêu đề',
//                       article['source'] ?? 'N/A'
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Thẻ tin tức (dùng trong Carousel)
//   Widget _buildNewsCard(String imageUrl, String title, String source) {
//     return Container(
//       width: 250, // Chiều rộng của 1 thẻ tin
//       margin: const EdgeInsets.only(left: 16),
//       child: Card(
//         clipBehavior: Clip.antiAlias, // Bo tròn ảnh
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Image.network(
//               imageUrl,
//               height: 120,
//               width: double.infinity,
//               fit: BoxFit.cover,
//               errorBuilder: (c, e, s) => Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     source,
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Danh mục (Category Grid)
//   Widget _buildCategorySection() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Danh mục',
//             style: Theme.of(context).textTheme.titleLarge,
//           ),
//           const SizedBox(height: 16),
//           GridView.count(
//             crossAxisCount: 2,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//             childAspectRatio: 1.2,
//             children: [
//               // 1. Chẩn đoán (Bỏ _isDiagnosing)
//               _buildCategoryCard(
//                 'Chẩn đoán Ảnh',
//                 Icons.camera_alt_outlined,
//                 Colors.blue,
//                 onTap: _startDiagnosis, // Gọi hàm chẩn đoán
//               ),
//               // 2. Lịch sử (Đổi index)
//               _buildCategoryCard(
//                 'Lịch sử',
//                 Icons.history_outlined,
//                 Colors.green,
//                 // === SỬA CHUYỂN TAB ===
//                 // Tab Lịch sử giờ là index 2 (0=Home, 1=Notif, 2=History)
//                 onTap: () => widget.onTabChange(2),
//                 // ====================
//               ),
//               // 3. Tra cứu (Placeholder)
//               _buildCategoryCard(
//                 'Tra cứu Bệnh',
//                 Icons.search_outlined,
//                 Colors.orange,
//                 onTap: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Tính năng sẽ sớm được cập nhật!'))
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Thẻ danh mục
//   Widget _buildCategoryCard(String title, IconData icon, Color color, {VoidCallback? onTap}) {
//     return Card(
//       color: color.withOpacity(0.1),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Icon(icon, size: 40, color: color),
//               const Spacer(),
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/services/api_service.dart';
import 'package:app/screens/result_screen.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:app/config/app_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:app/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<Map<String, dynamic>>> _newsFuture;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _profileFuture = _apiService.getProfile();
    _newsFuture = _loadNews();
  }

  Future<void> _handleRefresh() async {
    await context.read<ProfileProvider>().loadProfile();
    setState(() {
      _newsFuture = _loadNews();
    });
  }

  Future<List<Map<String, dynamic>>> _loadNews() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile);

      if (!hasConnection) {
        return [];
      }
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        } else {
          return [];
        }
      } catch (_) {
        return [];
      }
      final sources = await _apiService.getNewsSources();
      if (sources.isEmpty) return [];

      final vnExpress = sources.firstWhere(
            (s) => s['url'].toString().contains('vnexpress'),
        orElse: () => sources.first,
      );

      return await _apiService.scrapeNews(vnExpress['url']);
    } catch (e) {
      print("Lỗi tải tin tức: $e");
      return [];
    }
  }

  Future<XFile?> _cropImage(XFile imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt & Xoay ảnh',
          toolbarColor: const Color(0xFF0066CC),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
          activeControlsWidgetColor: const Color(0xFF0066CC),
        ),
        IOSUiSettings(
          title: 'Cắt & Xoay ảnh',
        ),
      ],
    );
    return croppedFile == null ? null : XFile(croppedFile.path);
  }

  Future<void> _startDiagnosis() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FBFF), Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066CC).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: Color(0xFF0066CC),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chọn nguồn ảnh',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn ảnh từ máy ảnh hoặc thư viện',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Máy ảnh',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Thư viện',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final XFile? originalImage = await _picker.pickImage(source: source);
    if (originalImage == null) return;

    final XFile? croppedImage = await _cropImage(originalImage);
    if (croppedImage == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Đang phân tích hình ảnh...",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Vui lòng đợi trong giây lát",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final result = await _apiService.diagnose(croppedImage);

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(diagnosisResult: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(e.toString())),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0066CC).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0066CC).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF0066CC)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF0066CC),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: _buildHeader(),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildNewsSection(),
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        String displayName = '...';
        String? avatarUrl;

        if (profileProvider.isLoading && profileProvider.profileData == null) {
          displayName = 'Đang tải...';
        } else if (profileProvider.profileData != null) {
          displayName = profileProvider.profileData?['fullName'] ?? 'Người dùng';
          avatarUrl = profileProvider.profileData?['avatar_url'];
        } else {
          displayName = 'Khách';
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Xin chào,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
                onBackgroundImageError: (avatarUrl != null)
                    ? (exception, stackTrace) {
                  print("Lỗi tải Avatar: $exception");
                }
                    : null,
                child: (avatarUrl == null)
                    ? const Icon(Icons.person, size: 28, color: Color(0xFF0066CC))
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tin tức Sức khỏe',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _newsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF0066CC),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildEmptyState(
                  icon: Icons.error_outline,
                  message: 'Lỗi tải tin tức',
                );
              }
              if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.article_outlined,
                  message: 'Không có tin tức',
                );
              }

              final articles = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  if (article['image'] == null) return const SizedBox.shrink();

                  return _buildNewsCard(
                    article['image']!,
                    article['title'] ?? 'Không có tiêu đề',
                    article['source'] ?? 'N/A',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(String imageUrl, String title, String source) {
    return Container(
      width: 280,
      height: 230,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066CC).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 130,
                      color: Colors.grey[100],
                      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: const Color(0xFF4CAF50)),
                          const SizedBox(width: 6),
                          Text(
                            'Mới',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.source_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              source,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Danh mục',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
            children: [
              _buildCategoryCard(
                'Chẩn đoán\nQua ảnh',
                Icons.camera_alt_outlined,
                const Color(0xFF0066CC),
                onTap: _startDiagnosis,
              ),
              _buildCategoryCard(
                'Lịch sử\nChuẩn đoán',
                Icons.history_outlined,
                const Color(0xFF4CAF50),
                onTap: () => widget.onTabChange(2),
              ),
              _buildCategoryCard(
                'Tra cứu\nBệnh lý',
                Icons.search_outlined,
                const Color(0xFFFF9800),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Tính năng sẽ sớm được cập nhật!'),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF0066CC),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}