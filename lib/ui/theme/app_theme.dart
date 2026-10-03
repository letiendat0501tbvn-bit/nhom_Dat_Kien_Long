import 'package:flutter/material.dart';

// Màu sắc và theme chung của ứng dụng (theo ảnh thiết kế).
class AppColors {
  static const primary = Color(0xFFC8352A); // đỏ chính
  static const accent = Color(0xFFFFB800); // vàng (nút xúc xắc)
  static const background = Color(0xFFFFFAF5); // nền
  static const text = Color(0xFF3B2A25); // chữ nâu đậm
  // Nền mục đang chọn: đỏ chính ~12% độ đậm
  static const selectedBg = Color(0x1FC8352A);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppColors.text,
            displayColor: AppColors.text,
          ),
    );
  }
}
