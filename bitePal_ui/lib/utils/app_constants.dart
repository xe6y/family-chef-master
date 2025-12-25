import 'package:flutter/material.dart';

/// 应用常量定义
class AppConstants {
  // 间距
  static const double spacingXS = 2.0;
  static const double spacingS = 4.0;
  static const double spacingM = 8.0;
  static const double spacingL = 12.0;
  static const double spacingXL = 16.0;
  static const double spacingXXL = 24.0;

  // 卡片相关
  static const double cardBorderRadius = 12.0;
  static const double cardImageHeight = 100.0;
  static const double cardPadding = 10.0;
  static const double cardBottomPadding = 0.0;

  // 按钮尺寸
  static const double addButtonSize = 28.0;
  static const double addButtonIconSize = 18.0;
  static const double addButtonBadgeSize = 12.0;

  // 颜色 - 使用主题色替代硬编码
  // 注意：这些颜色已迁移到 AppTheme，保留此处仅用于向后兼容
  // 建议：使用 Theme.of(context).colorScheme 获取颜色
  @Deprecated('使用 Theme.of(context).colorScheme.primary 替代')
  static const Color addButtonColor = Color(0xFF6B4423); // Brown-600
  
  @Deprecated('使用 AppColors.success 或 Theme.of(context).colorScheme 替代')
  static const Color addedBadgeColor = Color(0xFF10B981); // Green 500
  
  @Deprecated('使用 Theme.of(context).colorScheme.primaryContainer 替代')
  static const Color tagBlueBackground = Color(0xFFE3F2FD);
  
  @Deprecated('使用 Theme.of(context).colorScheme.primary 替代')
  static const Color tagBlueText = Color(0xFF1976D2);

  // 文本尺寸
  static const double textSizeXS = 9.0;
  static const double textSizeS = 11.0;
  static const double textSizeM = 12.0;
  static const double textSizeL = 14.0;
  static const double textSizeXL = 20.0;
  static const double textSizeXXL = 28.0;

  // 动画时长
  static const Duration snackBarDuration = Duration(seconds: 1);
  static const Duration snackBarLongDuration = Duration(seconds: 2);
}

