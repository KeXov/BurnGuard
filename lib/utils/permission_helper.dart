import 'package:flutter/material.dart';

class PermissionHelper {
  static Future<bool> checkAndRequestPermission(
    BuildContext context,
    Future<void> Function() requestPermission,
    bool hasPermission,
  ) async {
    if (!hasPermission) {
      if (!context.mounted) return false;

      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('需要悬浮窗权限'),
          content: const Text(
            'BurnGuard 需要悬浮窗权限才能显示防烧屏遮罩。\n\n'
            '点击"授权"后，请在系统设置中找到并启用 BurnGuard 的悬浮窗权限。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('授权'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        await requestPermission();
        return false;
      }
      return false;
    }

    return true;
  }

  static Future<void> showBatteryOptimizationDialog(
    BuildContext context,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('电池优化提示'),
        content: const Text(
          '为了确保防烧屏功能稳定运行，建议：\n\n'
          '1. 将 BurnGuard 加入电池优化白名单\n'
          '2. 在系统设置中允许 BurnGuard 后台运行\n'
          '3. 关闭省电模式或添加例外\n\n'
          '这样可以防止系统杀死前台服务，保证遮罩持续显示。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
