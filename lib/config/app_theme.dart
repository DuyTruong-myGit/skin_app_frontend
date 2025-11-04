import 'package:flutter/material.dart';

class AppTheme {
  // Màu sắc chủ đạo (Xanh dương y tế nhẹ nhàng)
  static const Color primaryColor = Color(0xFF3B82F6); // Blue-500
  static const Color primaryLightColor = Color(0xFFBFDBFE); // Blue-200

  // Màu nền
  static const Color backgroundColor = Color(0xFFF9FAFB); // Cool Gray-50

  // Màu chữ
  static const Color textColor = Color(0xFF1F2937); // Cool Gray-800
  static const Color textSecondaryColor = Color(0xFF6B7280); // Cool Gray-500

  // Định nghĩa ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,

      // Cấu hình AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cấu hình Text
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 14),
      ),

      // Cấu hình Nút bấm
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Cấu hình Ô nhập liệu
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
    );
  }
}