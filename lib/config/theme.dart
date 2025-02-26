import 'package:flutter/material.dart';

class AppTheme {
  // 颜色定义
  static const primaryColor = Color(0xFF000000);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const errorColor = Color(0xFFE53935);
  static const successColor = Color(0xFF43A047);
  static const dividerColor = Color(0xFFEEEEEE);

  // 文字样式
  static const TextStyle messageTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.black87,
    height: 1.5,
  );

  static const TextStyle timeTextStyle = TextStyle(
    fontSize: 12,
    color: Colors.black38,
  );

  static const TextStyle fileNameStyle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle fileSizeStyle = TextStyle(
    fontSize: 12,
    color: Colors.black45,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        surface: backgroundColor,
        error: errorColor,
        onSurface: primaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      scaffoldBackgroundColor: backgroundColor,
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle: TextStyle(color: backgroundColor),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
