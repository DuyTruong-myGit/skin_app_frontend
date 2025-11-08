import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum để định nghĩa các lựa chọn
enum ThemeModeOption { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  // Mặc định là theo hệ thống
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    // Tải lựa chọn đã lưu khi khởi động
    _loadThemeMode();
  }

  // Tải theme từ bộ nhớ
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Đọc 'theme' đã lưu (ví dụ: 'system', 'light', 'dark')
    final String themeString = prefs.getString('theme_mode') ?? 'system';

    _themeMode = _stringToThemeMode(themeString);
    notifyListeners();
  }

  // Chuyển đổi theme và lưu lại
  Future<void> setThemeMode(ThemeModeOption option) async {
    _themeMode = _optionToThemeMode(option);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(option));

    // Thông báo cho tất cả widget đang lắng nghe để "vẽ" lại
    notifyListeners();
  }

  // --- Các hàm tiện ích (helper) ---

  ThemeMode _optionToThemeMode(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  ThemeModeOption get currentThemeOption {
    switch (_themeMode) {
      case ThemeMode.light:
        return ThemeModeOption.light;
      case ThemeMode.dark:
        return ThemeModeOption.dark;
      default:
        return ThemeModeOption.system;
    }
  }

  String _themeModeToString(ThemeModeOption option) {
    return option.toString().split('.').last; // 'ThemeModeOption.system' -> 'system'
  }

  ThemeMode _stringToThemeMode(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}