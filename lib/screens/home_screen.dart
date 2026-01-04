import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:app/screens/static/feedback_screen.dart';
import 'package:app/services/api_service.dart';
import 'package:app/providers/profile_provider.dart';
import 'package:app/screens/result_screen.dart';
import 'package:app/screens/history_screen.dart';
import 'package:app/screens/disease/disease_list_screen.dart';
import 'package:app/screens/WatchApp/health_assistant_screen.dart';
import 'package:app/screens/heart_rate_monitor.dart';
import 'package:app/screens/notifications_screen.dart';
import 'package:app/screens/static/emergency_support_screen.dart';
// ==========================================
// 1. HOME SCREEN (Logic + Structure)
// ==========================================

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const HomeScreen({Key? key, required this.onTabChange}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late Future<List<Map<String, dynamic>>> _newsFuture;
  late Future<Map<String, dynamic>?> _watchDataFuture;
  late Future<Map<String, dynamic>?> _nextScheduleFuture;
  late Future<Map<String, int>> _statsFuture;

  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });

    _newsFuture = _loadNews();
    _watchDataFuture = _apiService.getLatestWatchData();
    _nextScheduleFuture = _loadNextSchedule(); // <--- Logic mới nằm trong hàm này
    _statsFuture = _loadStats();
    _countUnreadNotifications();
  }

  Future<void> _handleRefresh() async {
    await context.read<ProfileProvider>().loadProfile();
    await _countUnreadNotifications();

    setState(() {
      _newsFuture = _loadNews();
      _watchDataFuture = _apiService.getLatestWatchData();
      _nextScheduleFuture = _loadNextSchedule(); // <--- Reload lại lịch
      _statsFuture = _loadStats();
    });
  }

  // --- [ĐÃ SỬA] LOGIC LẤY LỊCH HẸN SẮP TỚI CHUẨN XÁC ---
  Future<Map<String, dynamic>?> _loadNextSchedule() async {
    try {
      final now = DateTime.now();

      // 1. Lấy danh sách công việc HÔM NAY
      final todayTasks = await _apiService.getDailyTasks(now);

      // Lọc công việc hôm nay
      final upcomingToday = todayTasks.where((task) {
        // Bỏ qua nếu đã hoàn thành
        if (task['log_status'] == 'completed') return false;

        // Kiểm tra thời gian (reminder_time dạng "HH:mm:ss" hoặc "HH:mm")
        final timeStr = task['reminder_time']?.toString();
        if (timeStr == null) return true; // Nếu không có giờ, coi như hợp lệ

        try {
          // Parse giờ để so sánh với giờ hiện tại
          final parts = timeStr.split(':');
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final taskTime = DateTime(now.year, now.month, now.day, h, m);

          return taskTime.isAfter(now); // Chỉ lấy việc trong tương lai
        } catch (e) {
          return true; // Lỗi parse thì cứ hiển thị cho an toàn
        }
      }).toList();

      // Nếu hôm nay có việc sắp tới -> Sắp xếp và trả về cái gần nhất
      if (upcomingToday.isNotEmpty) {
        upcomingToday.sort((a, b) => (a['reminder_time'] ?? '').compareTo(b['reminder_time'] ?? ''));
        final nextTask = upcomingToday.first;

        // Chuẩn hóa dữ liệu để UI hiển thị đúng (map field name cũ sang mới)
        return {
          'title': nextTask['title'],
          'note': nextTask['notes'] ?? nextTask['type'], // Sửa 'note' thành 'notes' nếu cần
          'time': _formatTimeDisplay(nextTask['reminder_time']),
          'date': now.toIso8601String(), // Gán ngày hôm nay
          'type': nextTask['type']
        };
      }

      // 2. Nếu hôm nay hết việc -> Lấy công việc NGÀY MAI
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTasks = await _apiService.getDailyTasks(tomorrow);

      final upcomingTomorrow = tomorrowTasks.where((task) {
        return task['log_status'] != 'completed';
      }).toList();

      if (upcomingTomorrow.isNotEmpty) {
        upcomingTomorrow.sort((a, b) => (a['reminder_time'] ?? '').compareTo(b['reminder_time'] ?? ''));
        final nextTask = upcomingTomorrow.first;

        return {
          'title': nextTask['title'],
          'note': nextTask['notes'] ?? nextTask['type'],
          'time': _formatTimeDisplay(nextTask['reminder_time']),
          'date': tomorrow.toIso8601String(), // Gán ngày mai
          'type': nextTask['type']
        };
      }

      return null; // Không có lịch nào
    } catch (e) {
      print("Lỗi load lịch: $e");
      return null;
    }
  }

  // Hàm phụ trợ để hiển thị giờ đẹp hơn (cắt giây)
  String _formatTimeDisplay(dynamic timeRaw) {
    if (timeRaw == null) return 'Cả ngày';
    String s = timeRaw.toString();
    if (s.length > 5) return s.substring(0, 5); // 08:30:00 -> 08:30
    return s;
  }

  // --- CÁC LOGIC KHÁC GIỮ NGUYÊN ---
  Future<void> _countUnreadNotifications() async {
    try {
      final notifications = await _apiService.getNotifications();
      int count = notifications.where((n) {
        final isRead = n['is_read'] == true || n['isRead'] == true || n['read_at'] != null;
        return !isRead;
      }).length;

      if (mounted) setState(() => _unreadNotificationCount = count);
    } catch (e) {
      print("Lỗi đếm thông báo: $e");
    }
  }

  Future<Map<String, int>> _loadStats() async {
    try {
      final results = await Future.wait([
        _apiService.getHistory(),
        _apiService.getAllSchedules(),
      ]);
      return {
        'diagnosis': (results[0] as List).length,
        'schedule': (results[1] as List).length,
        'report': 0
      };
    } catch (e) {
      return {'diagnosis': 0, 'schedule': 0, 'report': 0};
    }
  }

  Future<List<Map<String, dynamic>>> _loadNews() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile);
      if (!hasConnection) return [];

      final sources = await _apiService.getNewsSources();
      if (sources.isEmpty) return [];

      final vnExpress = sources.firstWhere(
            (s) => s['url'].toString().contains('vnexpress'),
        orElse: () => sources.first,
      );

      List<Map<String, dynamic>> newsList = await _apiService.scrapeNews(vnExpress['url']);
      newsList.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      return newsList;
    } catch (e) {
      return [];
    }
  }

  Future<void> _openNews(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView)) throw 'Lỗi';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
        ),
        IOSUiSettings(title: 'Cắt & Xoay ảnh'),
      ],
    );
    return croppedFile == null ? null : XFile(croppedFile.path);
  }

  Future<void> _startDiagnosis(ImageSource source) async {
    final XFile? originalImage = await _picker.pickImage(
      source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 90,
    );
    if (originalImage == null) return;

    final XFile? croppedImage = await _cropImage(originalImage);
    if (croppedImage == null) return;

    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => _buildLoadingDialog());

    try {
      final result = await _apiService.diagnose(croppedImage);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(diagnosisResult: result)));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog(e.toString());
    }
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Color(0xFF0066CC)),
            SizedBox(height: 24),
            Text("Đang phân tích...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("AI đang xử lý ảnh của bạn", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thông báo"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.blue,
        child: SingleChildScrollView(
          child: Column(
            children: [
              UserHeader(
                onProfileTap: () => widget.onTabChange(3),
                statsFuture: _statsFuture,
                unreadCount: _unreadNotificationCount,
                onNotificationTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  _countUnreadNotifications();
                },
              ),
              QuickActions(
                onCameraTap: () => _startDiagnosis(ImageSource.camera),
                onUploadTap: () => _startDiagnosis(ImageSource.gallery),
              ),
              Categories(
                onHistoryTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                onLookupTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseListScreen())),
                onAssistantTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthAssistantScreen())),
                onHeartRateTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HeartRateMonitor())),
                onDiagnosisTap: () => _startDiagnosis(ImageSource.camera),
              ),
              //HealthMetrics(watchDataFuture: _watchDataFuture),
              UpcomingAppointment(scheduleFuture: _nextScheduleFuture),
              HealthNews(newsFuture: _newsFuture, onNewsTap: _openNews),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// USER HEADER
// ==========================================
// ==========================================
// USER HEADER (ĐÃ CẬP NHẬT BIỂU ĐỒ)
// ==========================================
class UserHeader extends StatelessWidget {
  final VoidCallback onProfileTap;
  final Future<Map<String, int>> statsFuture;
  final int unreadCount;
  final VoidCallback onNotificationTap;

  const UserHeader({
    Key? key,
    required this.onProfileTap,
    required this.statsFuture,
    required this.unreadCount,
    required this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        final profile = provider.profileData;
        final name = profile?['fullName'] ?? 'Khách';
        final avatarUrl = profile?['avatar_url'];
        final displayId = profile?['id'] != null
            ? '#MED-${profile!['id'].toString().padLeft(4, '0')}'
            : '#MED-GUEST';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
          child: Column(
            children: [
              // 1. Header Profile & Notification (Giữ nguyên)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.shade100, width: 2),
                            image: DecorationImage(
                              image: (avatarUrl != null)
                                  ? NetworkImage(avatarUrl)
                                  : const NetworkImage('https://via.placeholder.com/150'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào,',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onNotificationTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(Icons.notifications_none_rounded,
                              size: 24, color: Colors.grey.shade700),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 2. BIỂU ĐỒ THỐNG KÊ (Phần mới thay thế)
              FutureBuilder<Map<String, int>>(
                future: statsFuture,
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {'diagnosis': 0, 'schedule': 0, 'report': 0};

                  // Tìm giá trị lớn nhất để tính chiều cao cột (tránh cột bị tràn hoặc quá thấp)
                  int maxVal = 1;
                  stats.forEach((key, value) {
                    if (value > maxVal) maxVal = value;
                  });

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tổng quan hoạt động",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "+${stats['diagnosis']} lượt mới",
                                style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Row chứa 3 cột biểu đồ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end, // Căn đáy các cột
                          children: [
                            _buildBarChartItem(
                              label: 'Chẩn đoán',
                              value: stats['diagnosis'] ?? 0,
                              maxVal: maxVal,
                              color: Colors.blue,
                              icon: Icons.camera_alt_outlined,
                            ),
                            _buildBarChartItem(
                              label: 'Lịch hẹn',
                              value: stats['schedule'] ?? 0,
                              maxVal: maxVal,
                              color: Colors.orange,
                              icon: Icons.calendar_today_outlined,
                            ),
                            _buildBarChartItem(
                              label: 'Báo cáo',
                              value: stats['report'] ?? 0,
                              maxVal: maxVal,
                              color: Colors.purple,
                              icon: Icons.assignment_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget con để vẽ từng cột trong biểu đồ
  Widget _buildBarChartItem({
    required String label,
    required int value,
    required int maxVal,
    required Color color,
    required IconData icon,
  }) {
    // Tính toán chiều cao tương đối (Max height = 80px)
    final double maxHeight = 80.0;
    final double height = (value / maxVal) * maxHeight;
    final double displayHeight = height < 10 ? 10.0 : height; // Chiều cao tối thiểu

    return Column(
      children: [
        // Bong bóng hiển thị số
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),

        // Cột biểu đồ
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Nền cột (mờ)
            Container(
              width: 12,
              height: maxHeight,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Cột giá trị (Gradient)
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 1),
              curve: Curves.easeOutQuart,
              tween: Tween<double>(begin: 0, end: displayHeight),
              builder: (context, h, _) {
                return Container(
                  width: 12,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [color.withOpacity(0.7), color],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Icon và Label
        Column(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        )
      ],
    );
  }
}

// ==========================================
// QUICK ACTIONS
// ==========================================
class QuickActions extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onUploadTap;
  const QuickActions({Key? key, required this.onCameraTap, required this.onUploadTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'id': 'camera',
        'title': 'Chụp ảnh',
        'icon': Icons.camera_alt_outlined,
        'bg': Colors.blue.shade50,
        'text': Colors.blue.shade700,
        'border': Colors.blue.shade200,
        'onTap': onCameraTap
      },
      {
        'id': 'upload',
        'title': 'Tải ảnh',
        'icon': Icons.upload_outlined,
        'bg': Colors.purple.shade50,
        'text': Colors.purple.shade700,
        'border': Colors.purple.shade200,
        'onTap': onUploadTap
      },
      {
        'id': 'report',
        'title': 'Báo cáo',
        'icon': Icons.description_outlined,
        'bg': Colors.orange.shade50,
        'text': Colors.orange.shade700,
        'border': Colors.orange.shade200,
        // === SỬA DÒNG NÀY ===
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeedbackScreen()),
          );
        }
      },
      {
        'id': 'emergency',
        'title': 'Khẩn cấp',
        'icon': Icons.phone_outlined,
        'bg': Colors.red.shade50,
        'text': Colors.red.shade700,
        'border': Colors.red.shade200,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencySupportScreen()),
          );
        }
      },
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thao tác nhanh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: action['bg'] as Color,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: action['onTap'] as VoidCallback,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border.all(color: action['border'] as Color), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Icon(action['icon'] as IconData, size: 20, color: action['text'] as Color),
                            const SizedBox(height: 6),
                            Text(action['title'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: action['text'] as Color)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CATEGORIES
// ==========================================
class Categories extends StatelessWidget {
  final VoidCallback onHistoryTap;
  final VoidCallback onLookupTap;
  final VoidCallback onAssistantTap;
  final VoidCallback onHeartRateTap;
  final VoidCallback onDiagnosisTap;
  const Categories({Key? key, required this.onHistoryTap, required this.onLookupTap, required this.onAssistantTap, required this.onHeartRateTap, required this.onDiagnosisTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final categories = [
      {'title': 'Chẩn đoán qua ảnh', 'icon': Icons.camera_alt_outlined, 'desc': 'AI phân tích hình ảnh da liễu', 'stats': 'Bắt đầu', 'onTap': onDiagnosisTap},
      {'title': 'Lịch sử chẩn đoán', 'icon': Icons.history, 'desc': 'Xem lại kết quả đã lưu', 'stats': 'Xem ngay', 'onTap': onHistoryTap},
      {'title': 'Tra cứu bệnh', 'icon': Icons.description_outlined, 'desc': 'Cơ sở dữ liệu bệnh học', 'stats': '500+ bệnh', 'onTap': onLookupTap},
      {'title': 'Trợ lý sức khỏe', 'icon': Icons.trending_up, 'desc': 'Tư vấn và theo dõi sức khỏe', 'stats': 'Watch App', 'onTap': onAssistantTap},
      {'title': 'Đo nhịp tim', 'icon': Icons.favorite_outline, 'desc': 'Theo dõi nhịp tim qua Camera', 'stats': 'Đo ngay', 'onTap': onHeartRateTap},
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dịch vụ chuyên khoa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              const Text('Xem tất cả →', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: cat['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                          child: Icon(cat['icon'] as IconData, size: 20, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(cat['desc'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                          child: Text(cat['stats'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ==========================================
// HEALTH METRICS
// ==========================================
// ==========================================
// HEALTH METRICS (ĐÃ CẬP NHẬT LOGIC REAL-TIME)
// ==========================================
class HealthMetrics extends StatelessWidget {
  final Future<Map<String, dynamic>?> watchDataFuture;
  const HealthMetrics({Key? key, required this.watchDataFuture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chỉ số sức khỏe (Mới nhất)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              // Thêm nút refresh nhỏ hoặc text chỉ dẫn
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<Map<String, dynamic>?>(
            future: watchDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              }

              // 1. XỬ LÝ DỮ LIỆU THẬT
              String heartRate = '--';
              String spo2 = '--';
              int hrVal = 0;
              int spo2Val = 0;

              // Nếu có data thì parse
              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!;
                heartRate = data['heartRate']?.toString() ?? '--';
                spo2 = data['spo2']?.toString() ?? '--';

                hrVal = int.tryParse(heartRate) ?? 0;
                spo2Val = int.tryParse(spo2) ?? 0;
              }

              // 2. LOGIC ĐÁNH GIÁ (Thay cho chấm điểm giả)
              String statusTitle = "Chưa có dữ liệu";
              String statusDesc = "Vui lòng kết nối đồng hồ để đo.";
              Color statusColor = Colors.grey;
              IconData statusIcon = Icons.help_outline;

              if (hrVal > 0) {
                if (hrVal > 100) {
                  statusTitle = "Nhịp tim Cao";
                  statusDesc = "Bạn vừa vận động mạnh? Nếu không, hãy ngồi nghỉ ngơi ngay.";
                  statusColor = Colors.orange;
                  statusIcon = Icons.warning_amber_rounded;
                } else if (spo2Val > 0 && spo2Val < 95) {
                  statusTitle = "SpO2 Thấp";
                  statusDesc = "Lượng oxy trong máu hơi thấp. Hãy hít thở sâu và đều.";
                  statusColor = Colors.orange;
                  statusIcon = Icons.air;
                } else {
                  statusTitle = "Sức khỏe Ổn định";
                  statusDesc = "Các chỉ số của bạn đang ở mức bình thường. Tiếp tục duy trì nhé!";
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle_outline;
                }
              }

              // 3. UI CARDS
              final metrics = [
                {
                  'label': 'Nhịp tim',
                  'value': heartRate,
                  'unit': 'bpm',
                  'icon': Icons.favorite,
                  'color': Colors.redAccent,
                  'bgColor': Colors.red.shade50
                },
                {
                  'label': 'SpO2',
                  'value': spo2,
                  'unit': '%',
                  'icon': Icons.water_drop,
                  'color': Colors.blueAccent,
                  'bgColor': Colors.blue.shade50
                },
                // Có thể thêm Nhiệt độ hoặc Huyết áp nếu Database có
              ];

              return Column(
                children: [
                  // Row hiển thị 2 thẻ chỉ số
                  Row(
                    children: metrics.map((m) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: m['bgColor'] as Color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 20),
                            ),
                            const SizedBox(height: 12),
                            Text(m['value'] as String,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text(m['unit'] as String,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            Text(m['label'] as String,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),

                  const SizedBox(height: 16),

                  // 4. THẺ INSIGHT (Thay thế cho chấm điểm)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusTitle,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor.withOpacity(0.8) // Đậm hơn chút
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusDesc,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// UPCOMING APPOINTMENT
// ==========================================
class UpcomingAppointment extends StatelessWidget {
  final Future<Map<String, dynamic>?> scheduleFuture;
  const UpcomingAppointment({Key? key, required this.scheduleFuture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lịch hẹn sắp tới', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>?>(
              future: scheduleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()));

                if (!snapshot.hasData || snapshot.data == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: Center(child: Column(children: const [Icon(Icons.event_busy, color: Colors.grey), SizedBox(height: 8), Text('Không có lịch hẹn sắp tới', style: TextStyle(color: Colors.grey))])),
                  );
                }

                final item = snapshot.data!;
                DateTime? date;
                try { date = DateTime.parse(item['date']); } catch (_) {}

                final dayStr = date != null ? date.day.toString() : '--';
                final monthStr = date != null ? 'THÁNG ${date.month}' : '';
                final title = item['title'] ?? 'Lịch hẹn';
                final note = item['note'] ?? 'Không có ghi chú';
                final time = item['time'] ?? 'Cả ngày';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.3), border: Border.all(color: Colors.blue.shade100, width: 2), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60, padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(8)),
                            child: Column(children: [Text(dayStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1)), const SizedBox(height: 4), Text(monthStr, style: const TextStyle(fontSize: 9, color: Colors.white, letterSpacing: 0.5))]),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(note, style: TextStyle(fontSize: 13, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis)]),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)), child: Text('Sắp tới', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green.shade700))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.shade300, height: 1),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.access_time, time),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.notes, note),
                    ],
                  ),
                );
              }
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 16, color: Colors.grey.shade500), const SizedBox(width: 12), Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)))]);
  }
}

// ==========================================
// HEALTH NEWS
// ==========================================
class HealthNews extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> newsFuture;
  final Function(String) onNewsTap;
  const HealthNews({Key? key, required this.newsFuture, required this.onNewsTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [Icon(Icons.check_circle_outline, size: 20, color: Colors.black87), SizedBox(width: 8), Text('Tài liệu y khoa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))]),
              const Text('Thư viện →', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: newsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: CircularProgressIndicator()));
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Text("Không có tin tức mới");
              final displayItems = snapshot.data!.take(5).toList();
              return Column(children: displayItems.map((news) {
                return InkWell(onTap: () { if (news['link'] != null) onNewsTap(news['link']); }, child: _buildNewsCard(news));
              }).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(4), child: Container(width: 80, height: 80, color: Colors.grey.shade100, child: Image.network(news['image'] ?? '', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey)))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text('TIN TỨC', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 1)), Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('•', style: TextStyle(color: Colors.grey.shade400))), Expanded(child: Text(news['source'] ?? 'VnExpress', style: TextStyle(fontSize: 9, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis))]),
                const SizedBox(height: 4),
                Text(news['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [Icon(Icons.access_time, size: 10, color: Colors.grey.shade500), const SizedBox(width: 4), Text('Mới cập nhật', style: TextStyle(fontSize: 9, color: Colors.grey.shade500))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}