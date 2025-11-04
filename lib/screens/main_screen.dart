import 'package:flutter/material.dart';
import 'package:app/config/app_theme.dart'; // Import theme
import 'package:app/screens/history_screen.dart';
import 'package:app/screens/home_screen.dart'; // Đây là HomeScreen cũ
import 'package:app/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Tab đang được chọn

  // Danh sách các màn hình (Tab)
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Tab 0: Trang chủ (chẩn đoán)
    HistoryScreen(), // Tab 1: Lịch sử
    ProfileScreen(), // Tab 2: Hồ sơ
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hiển thị màn hình con tương ứng với tab được chọn
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      // Thanh điều hướng dưới cùng
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Chẩn đoán',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor, // Dùng màu theme
        unselectedItemColor: AppTheme.textSecondaryColor,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, // Đảm bảo 3 tab luôn hiển thị
      ),
    );
  }
}