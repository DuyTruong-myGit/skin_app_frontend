import 'package:flutter/material.dart';
import 'package:app/config/app_theme.dart';
import 'package:app/screens/history_screen.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/screens/profile_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/screens/admin/admin_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _storage = const FlutterSecureStorage();
  String _userRole = 'user'; // Mặc định là user

  // Danh sách Tab động
  final List<Widget> _widgetOptions = [];
  final List<BottomNavigationBarItem> _navBarItems = [];

  @override
  void initState() {
    super.initState();
    // Kiểm tra role để build UI
    _checkUserRoleAndBuildTabs();
  }

  Future<void> _checkUserRoleAndBuildTabs() async {
    String? role = await _storage.read(key: 'role');
    setState(() {
      _userRole = role ?? 'user';

      // Xây dựng danh sách Tab cơ bản
      _widgetOptions.add(HomeScreen());
      _navBarItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.medical_services_outlined),
        activeIcon: Icon(Icons.medical_services),
        label: 'Chẩn đoán',
      ));

      _widgetOptions.add(HistoryScreen());
      _navBarItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.history_outlined),
        activeIcon: Icon(Icons.history),
        label: 'Lịch sử',
      ));

      _widgetOptions.add(ProfileScreen());
      _navBarItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Hồ sơ',
      ));

      // NẾU LÀ ADMIN, THÊM TAB THỨ 4
      if (_userRole == 'admin') {
        _widgetOptions.add(AdminDashboardScreen()); // Màn hình admin
        _navBarItems.add(const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Quản lý',
        ));
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading cho đến khi Tab được build xong
    if (_navBarItems.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navBarItems, // Dùng list động
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}