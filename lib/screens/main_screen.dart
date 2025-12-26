import 'package:flutter/material.dart';
import 'package:app/config/app_theme.dart';
import 'package:app/screens/history_screen.dart';
import 'package:app/screens/home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/screens/admin/admin_dashboard_screen.dart';
import 'package:app/widgets/network_banner.dart';
import 'package:app/screens/settings_screen.dart';
import 'package:app/screens/chat_screen.dart';
import 'package:app/screens/notifications_screen.dart';
import 'package:app/screens/schedule/schedule_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _storage = const FlutterSecureStorage();
  String _userRole = 'user';

  final List<Widget> _widgetOptions = [];
  final List<BottomNavigationBarItem> _navBarItems = [];

  // === 1. BIẾN ĐỂ LƯU VỊ TRÍ NÚT CHAT (LOGIC GIỮ NGUYÊN) ===
  Offset _fabOffset = const Offset(300, 600);
  bool _isFabInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkUserRoleAndBuildTabs();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // === LOGIC PHÂN QUYỀN (GIỮ NGUYÊN) ===
  Future<void> _checkUserRoleAndBuildTabs() async {
    final role = await _storage.read(key: 'role');
    setState(() {
      _userRole = role ?? 'user';

      _widgetOptions.clear();
      _navBarItems.clear();

      _widgetOptions.add(HomeScreen(onTabChange: _onItemTapped));
      _navBarItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Trang chủ',
      ));

      _widgetOptions.add(const NotificationsScreen());
      _navBarItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.notifications_outlined),
        activeIcon: Icon(Icons.notifications),
        label: 'Thông báo',
      ));

      _widgetOptions.add(const ScheduleScreen());
      _navBarItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today),
        label: 'Lịch trình',
      ));

      _widgetOptions.add(const SettingsScreen());
      _navBarItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Cài đặt',
      ));

      if (_userRole == 'admin') {
        _widgetOptions.add(const AdminDashboardScreen());
        _navBarItems.add(const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Quản lý',
        ));
      }

      if (_selectedIndex >= _widgetOptions.length) {
        _selectedIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // === 2. TÍNH TOÁN VỊ TRÍ BAN ĐẦU (LOGIC GIỮ NGUYÊN) ===
    if (!_isFabInitialized) {
      final screenSize = MediaQuery.of(context).size;
      _fabOffset = Offset(screenSize.width - 84, screenSize.height - 160);
      _isFabInitialized = true;
    }

    // Màn hình Loading khi chưa load xong Tab
    if (_navBarItems.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB), // Màu nền chuẩn Design System
        body: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300), // Viền chuẩn style Card
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0066CC), // Màu Primary
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Màu nền chuẩn Design System

      // === 3. STACK BODY (LOGIC GIỮ NGUYÊN) ===
      body: Stack(
        children: [
          // Lớp dưới cùng: Nội dung chính
          Column(
            children: [
              const NetworkBanner(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _widgetOptions,
                ),
              ),
            ],
          ),

          // Lớp trên cùng: Nút Chatbot Draggable
          Positioned(
            left: _fabOffset.dx,
            top: _fabOffset.dy,
            child: GestureDetector(
              // Logic kéo thả giữ nguyên
              onPanUpdate: (details) {
                setState(() {
                  final screenSize = MediaQuery.of(context).size;
                  double newX = _fabOffset.dx + details.delta.dx;
                  double newY = _fabOffset.dy + details.delta.dy;

                  if (newX < 0) newX = 0;
                  if (newX > screenSize.width - 64) newX = screenSize.width - 64;
                  if (newY < 0) newY = 0;
                  if (newY > screenSize.height - 140) newY = screenSize.height - 140;

                  _fabOffset = Offset(newX, newY);
                });
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
              // UI Nút Chat: Update theo Design System (Gradient + Viền trắng)
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF00B4D8)], // Primary -> Secondary
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2), // Viền trắng nổi bật
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066CC).withOpacity(0.3), // Shadow nhẹ hơn
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.psychology_outlined, // Icon AI
                      color: Colors.white,
                      size: 32,
                    ),
                    // Indicator online (Chấm xanh lá)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50), // Green Success
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // === BOTTOM NAVIGATION BAR (UPDATE THEO DESIGN SYSTEM) ===
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            // Thay thế BoxShadow đậm bằng Border nhẹ phía trên để clean hơn
            border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60, // Chiều cao thanh điều hướng
              child: BottomNavigationBar(
                items: _navBarItems,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedFontSize: 11.0,
                unselectedFontSize: 11.0,
                // Màu Primary cho Active
                selectedItemColor: const Color(0xFF0066CC),
                // Màu Grey.shade600 cho Inactive (theo prompt)
                unselectedItemColor: Colors.grey.shade600,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}