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

      _widgetOptions.add(const HistoryScreen());
      _navBarItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.history_outlined),
        activeIcon: Icon(Icons.history),
        label: 'Lịch sử',
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
    if (_navBarItems.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.support_agent, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // === SỬA LỖI OVERFLOW TẠI ĐÂY ===
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          canvasColor: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : AppTheme.darkCardColor,
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          // Bỏ height: 80
          child: BottomNavigationBar(
            items: _navBarItems,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,

            // Giảm kích thước font để vừa
            selectedFontSize: 12.0,
            unselectedFontSize: 12.0,
          ),
        ),
      ),
      // ==============================
    );
  }
}