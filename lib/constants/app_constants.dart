import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 预设遮罩颜色
  static const List<Map<String, String>> overlayColors = [
    {'name': '黑色', 'value': '#000000'},
    {'name': '深灰', 'value': '#1a1a1a'},
    {'name': '灰色', 'value': '#4a4a4a'},
    {'name': '深蓝', 'value': '#0a1a2a'},
    {'name': '深紫', 'value': '#1a0a2a'},
  ];

  // 解析颜色
  static Color parseColor(String colorHex) {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }
}

class AppDimensions {
  AppDimensions._();

  // 间距
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // 圆角
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;

  // 图标大小
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 48.0;

  // 按钮大小
  static const double buttonSize = 56.0;

  // 高度限制
  static const double maxOverlayHeight = 300.0;
  static const double maxBorderRadius = 100.0;
}

class AppStrings {
  AppStrings._();

  // 应用信息
  static const String appName = 'BurnGuard';
  static const String appVersion = '2.0.0';

  // 权限
  static const String overlayPermissionGranted = '悬浮窗权限已授予';
  static const String overlayPermissionRequired = '需要悬浮窗权限';
  static const String accessibilityPermissionGranted = '无障碍权限已授予';
  static const String accessibilityPermissionRequired = '需要无障碍权限';

  // 状态
  static const String overlayRunning = '运行中';
  static const String overlayStopped = '已停止';
  static const String overlayEnabled = '防烧屏已开启';
  static const String overlayDisabled = '防烧屏已关闭';

  // 设置
  static const String sizeSettings = '尺寸设置';
  static const String colorSettings = '颜色选择';
  static const String animationMode = '动画模式';
  static const String advancedSettings = '高级设置';

  // 模式
  static const String modeStatic = '静态';
  static const String modeDrift = '漂移';
  static const String modeBreathing = '呼吸';
  static const String modeRandom = '随机';
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyMedium = TextStyle(fontSize: 14);

  static const TextStyle bodySmall = TextStyle(fontSize: 12);
}
