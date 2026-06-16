import 'package:flutter/material.dart';

/// 全局主题定义
///
/// 所有页面和插件的样式都从这里派生，确保视觉一致性。
class AppTheme {
  AppTheme._();

  /// 统一圆角 — 16px，与用户偏好一致
  static const double borderRadius = 16;

  /// 中等圆角 — 12px
  static const double borderRadiusMedium = 12;

  /// 小圆角 — 8px
  static const double borderRadiusSmall = 8;

  /// 全局主题
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF9800), // 橙色种子
        brightness: Brightness.light,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusMedium),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );
}
