import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import 'package:app/services/api_service.dart';
import 'package:app/providers/profile_provider.dart';
import 'package:app/screens/result_screen.dart';
import 'package:app/screens/history_screen.dart';
import 'package:app/screens/disease/disease_list_screen.dart';
import 'package:app/screens/WatchApp/health_assistant_screen.dart';
import 'package:app/screens/heart_rate_monitor.dart';
import 'package:app/screens/notifications_screen.dart';

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
      final schedules = await _apiService.getAllSchedules();
      if (schedules.isEmpty) return null;

      final now = DateTime.now();
      // Đưa thời gian hiện tại về 00:00:00 để so sánh chính xác theo NGÀY
      final today = DateTime(now.year, now.month, now.day);

      final upcoming = schedules.where((s) {
        // 1. Kiểm tra ngày hợp lệ
        if (s['date'] == null) return false;

        DateTime? sDate;
        try {
          sDate = DateTime.parse(s['date']);
        } catch (_) {
          return false; // Bỏ qua nếu ngày lỗi format
        }

        // 2. Loại bỏ các lịch đã hoàn thành/đã hủy (chỉ lấy pending/confirmed)
        // Nếu status null thì vẫn hiển thị để an toàn
        if (s['status'] == 'completed' || s['status'] == 'cancelled') return false;

        // 3. Logic ngày: Lấy ngày của lịch (bỏ giờ phút)
        final checkDate = DateTime(sDate.year, sDate.month, sDate.day);

        // Điều kiện: Ngày lịch >= Ngày hôm nay (Tương lai hoặc Hôm nay)
        return checkDate.isAtSameMomentAs(today) || checkDate.isAfter(today);
      }).toList();

      if (upcoming.isEmpty) return null;

      // 4. Sắp xếp tăng dần: Ngày gần nhất lên đầu
      upcoming.sort((a, b) {
        final d1 = DateTime.parse(a['date']);
        final d2 = DateTime.parse(b['date']);
        int cmp = d1.compareTo(d2);

        // Nếu cùng ngày thì so sánh giờ (nếu có field 'time')
        if (cmp == 0 && a['time'] != null && b['time'] != null) {
          return (a['time'] as String).compareTo(b['time']);
        }
        return cmp;
      });

      // Lấy cái đầu tiên (Gần nhất)
      return upcoming.first;
    } catch (e) {
      print("Lỗi load lịch: $e");
      return null;
    }
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
              HealthMetrics(watchDataFuture: _watchDataFuture),
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
class UserHeader extends StatelessWidget {
  final VoidCallback onProfileTap;
  final Future<Map<String, int>> statsFuture;
  final int unreadCount;
  final VoidCallback onNotificationTap;

  const UserHeader({
    Key? key, required this.onProfileTap, required this.statsFuture, required this.unreadCount, required this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          final profile = provider.profileData;
          final name = profile?['fullName'] ?? 'Khách';
          final avatarUrl = profile?['avatar_url'];
          final displayId = profile?['id'] != null ? '#MED-${profile!['id'].toString().padLeft(4, '0')}' : '#MED-GUEST';

          return Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: onProfileTap,
                      child: Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                              image: DecorationImage(
                                image: (avatarUrl != null) ? NetworkImage(avatarUrl) : const NetworkImage('https://via.placeholder.com/150'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('HỒ SƠ NGƯỜI DÙNG', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                              const SizedBox(height: 2),
                              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(height: 2),
                              Text('ID: $displayId', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                            child: Icon(Icons.notifications_outlined, size: 20, color: Colors.grey.shade700),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -4, right: -4,
                              child: Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Center(child: Text(unreadCount > 9 ? '9+' : '$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.grey.shade50, Colors.grey.shade100]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tình trạng sức khỏe', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              const Text('Ổn định', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                            ],
                          ),
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                            child: Center(child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Center(child: Text('A+', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.shade300, height: 1),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, int>>(
                          future: statsFuture,
                          builder: (context, snapshot) {
                            final stats = snapshot.data ?? {'diagnosis': 0, 'schedule': 0, 'report': 0};
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Chẩn đoán', '${stats['diagnosis']}'),
                                _buildStatItem('Lịch hẹn', '${stats['schedule']}'),
                                _buildStatItem('Báo cáo', '${stats['report']}'),
                              ],
                            );
                          }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
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
      {'id': 'camera', 'title': 'Chụp ảnh', 'icon': Icons.camera_alt_outlined, 'bg': Colors.blue.shade50, 'text': Colors.blue.shade700, 'border': Colors.blue.shade200, 'onTap': onCameraTap},
      {'id': 'upload', 'title': 'Tải ảnh', 'icon': Icons.upload_outlined, 'bg': Colors.purple.shade50, 'text': Colors.purple.shade700, 'border': Colors.purple.shade200, 'onTap': onUploadTap},
      {'id': 'report', 'title': 'Báo cáo', 'icon': Icons.description_outlined, 'bg': Colors.orange.shade50, 'text': Colors.orange.shade700, 'border': Colors.orange.shade200, 'onTap': () {}},
      {'id': 'emergency', 'title': 'Khẩn cấp', 'icon': Icons.phone_outlined, 'bg': Colors.red.shade50, 'text': Colors.red.shade700, 'border': Colors.red.shade200, 'onTap': () {}},
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
          const Text('Chỉ số sức khỏe', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>?>(
            future: watchDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()));

              String heartRate = '--', spo2 = '--', humidity = '--';
              String hrStatus = 'normal', spo2Status = 'normal';

              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!;
                heartRate = data['heartRate']?.toString() ?? '--';
                spo2 = data['spo2']?.toString() ?? '--';
                final hrVal = int.tryParse(heartRate) ?? 0;
                final spo2Val = int.tryParse(spo2) ?? 0;
                if (hrVal > 100 || hrVal < 50 && hrVal != 0) hrStatus = 'warning';
                if (spo2Val < 95 && spo2Val != 0) spo2Status = 'warning';
              }

              final metrics = [
                {'label': 'Nhịp tim', 'value': heartRate, 'unit': 'bpm', 'icon': Icons.favorite_outline, 'trend': 'stable', 'trendVal': '', 'status': hrStatus},
                {'label': 'SpO2', 'value': spo2, 'unit': '%', 'icon': Icons.trending_up, 'trend': 'stable', 'trendVal': '', 'status': spo2Status},
                {'label': 'Độ ẩm da', 'value': humidity, 'unit': '%', 'icon': Icons.water_drop_outlined, 'trend': 'stable', 'trendVal': '', 'status': 'normal'},
              ];

              return Row(children: metrics.map((m) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _buildMetricCard(m)))).toList());
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Điểm sức khỏe tổng thể', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text('85/100', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))]),
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: const LinearProgressIndicator(value: 0.85, minHeight: 8, backgroundColor: Color(0xFFEEEEEE), valueColor: AlwaysStoppedAnimation<Color>(Colors.green))),
                const SizedBox(height: 8),
                Text('Tình trạng tốt. Tiếp tục duy trì lối sống lành mạnh.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> m) {
    Color border = m['status'] == 'normal' ? Colors.green.shade200 : Colors.yellow.shade200;
    Color bg = m['status'] == 'normal' ? Colors.green.shade50.withOpacity(0.5) : Colors.yellow.shade50.withOpacity(0.5);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(m['icon'] as IconData, size: 16, color: Colors.grey.shade700),
          const SizedBox(height: 8),
          Text(m['value'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1)),
          const SizedBox(height: 2),
          Text(m['unit'], style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(m['label'], style: TextStyle(fontSize: 10, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
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