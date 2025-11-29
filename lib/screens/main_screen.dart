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

  // === 1. BIẾN ĐỂ LƯU VỊ TRÍ NÚT CHAT ===
  Offset _fabOffset = const Offset(300, 600); // Vị trí mặc định tạm thời
  bool _isFabInitialized = false; // Cờ để kiểm tra đã set vị trí ban đầu chưa

  @override
  void initState() {
    super.initState();
    _checkUserRoleAndBuildTabs();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

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
    // === 2. TÍNH TOÁN VỊ TRÍ BAN ĐẦU (GÓC DƯỚI PHẢI) ===
    if (!_isFabInitialized) {
      final screenSize = MediaQuery.of(context).size;
      // Đặt mặc định cách phải 20, cách dưới 20
      _fabOffset = Offset(screenSize.width - 84, screenSize.height - 160);
      _isFabInitialized = true;
    }

    if (_navBarItems.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        body: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066CC).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      // === 3. BỌC BODY TRONG STACK ===
      body: Stack(
        children: [
          // Lớp dưới cùng: Nội dung chính của App
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

          // Lớp trên cùng: Nút Chatbot di chuyển được
          Positioned(
            left: _fabOffset.dx,
            top: _fabOffset.dy,
            child: GestureDetector(
              // Sự kiện kéo thả
              onPanUpdate: (details) {
                setState(() {
                  final screenSize = MediaQuery.of(context).size;
                  // Tính toán vị trí mới
                  double newX = _fabOffset.dx + details.delta.dx;
                  double newY = _fabOffset.dy + details.delta.dy;

                  // Giới hạn không cho kéo ra khỏi màn hình
                  // 64 là kích thước nút, chừa lề một chút
                  if (newX < 0) newX = 0;
                  if (newX > screenSize.width - 64) newX = screenSize.width - 64;
                  if (newY < 0) newY = 0;
                  // Trừ đi chiều cao BottomBar (khoảng 60-80) để không bị che
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
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066CC).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
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

      // === 4. ĐÃ XÓA THUỘC TÍNH floatingActionButton Ở ĐÂY ===

      // === BOTTOM NAVIGATION BAR (GIỮ NGUYÊN) ===
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60,
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
                selectedItemColor: const Color(0xFF0066CC),
                unselectedItemColor: const Color(0xFF999999),
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