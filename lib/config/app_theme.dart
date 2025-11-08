import 'package:flutter/material.dart';

class AppTheme {
  // === MÀU SÁNG ===
  static const Color primaryColor = Color(0xFF3B82F6); // Blue-500
  static const Color primaryLightColor = Color(0xFFBFDBFE); // Blue-200
  static const Color backgroundColor = Color(0xFFF9FAFB); // Cool Gray-50
  static const Color textColor = Color(0xFF1F2937); // Cool Gray-800
  static const Color textSecondaryColor = Color(0xFF6B7280); // Cool Gray-500

  // === MÀU TỐI ===
  static const Color darkBackgroundColor = Color(0xFF1F2937); // Cool Gray-800
  static const Color darkCardColor = Color(0xFF374151); // Cool Gray-700
  static const Color darkTextColor = Color(0xFFF9FAFB); // Cool Gray-50
  static const Color darkTextSecondaryColor = Color(0xFF9CA3AF); // Cool Gray-400

  // === THEME SÁNG ===
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLightColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
      ),
      // === SỬA LỖI 1 Ở ĐÂY ===
      cardTheme: CardThemeData(
        elevation: 0.5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
      ),
    );
  }

  // === THEME TỐI (MỚI) ===
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: TextStyle(color: darkTextColor, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: darkTextColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: darkTextColor, fontSize: 16),
        bodyMedium: TextStyle(color: darkTextSecondaryColor, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLightColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: darkTextSecondaryColor),
        prefixIconColor: darkTextSecondaryColor,
      ),
      // === SỬA LỖI 2 Ở ĐÂY ===
      cardTheme: CardThemeData(
        elevation: 0.5,
        color: darkCardColor, // Màu thẻ tối
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCardColor, // Màu BottomNav tối
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextSecondaryColor,
      ),
    );
  }
}