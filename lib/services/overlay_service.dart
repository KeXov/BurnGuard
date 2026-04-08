import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:burn_guard/models/overlay_config.dart';
import 'package:burn_guard/utils/result.dart';
import 'package:burn_guard/utils/logger.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.burnguard/overlay');
  static const EventChannel _eventChannel = EventChannel(
    'com.burnguard/overlay_events',
  );
  static const String _tag = 'OverlayService';

  static Future<Result<bool>> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
      Logger.debug('Overlay permission check: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to check overlay permission', _tag, e);
      return Result.failure('检查悬浮窗权限失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to check overlay permission', _tag, e);
      return Result.failure('检查悬浮窗权限失败: $e');
    }
  }

  static Future<Result<bool>> requestOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestOverlayPermission',
      );
      Logger.info('Overlay permission request result: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to request overlay permission', _tag, e);
      return Result.failure('请求悬浮窗权限失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to request overlay permission', _tag, e);
      return Result.failure('请求悬浮窗权限失败: $e');
    }
  }

  static Future<Result<bool>> hasAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'hasAccessibilityPermission',
      );
      Logger.debug('Accessibility permission check: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to check accessibility permission', _tag, e);
      return Result.failure('检查无障碍权限失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to check accessibility permission', _tag, e);
      return Result.failure('检查无障碍权限失败: $e');
    }
  }

  static Future<Result<bool>> isAccessibilityEnabledInSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isAccessibilityEnabledInSettings',
      );
      Logger.debug('Accessibility enabled in settings: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to check accessibility settings', _tag, e);
      return Result.failure('检查无障碍设置失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to check accessibility settings', _tag, e);
      return Result.failure('检查无障碍设置失败: $e');
    }
  }

  static Future<Result<bool>> isAccessibilityServiceRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isAccessibilityServiceRunning',
      );
      Logger.debug('Accessibility service running: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to check accessibility service', _tag, e);
      return Result.failure('检查无障碍服务失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to check accessibility service', _tag, e);
      return Result.failure('检查无障碍服务失败: $e');
    }
  }

  static Future<Result<bool>> requestAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestAccessibilityPermission',
      );
      Logger.info('Accessibility permission request result: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to request accessibility permission', _tag, e);
      return Result.failure('请求无障碍权限失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to request accessibility permission', _tag, e);
      return Result.failure('请求无障碍权限失败: $e');
    }
  }

  static Future<Result<bool>> startOverlay(OverlayConfig config) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'startOverlay',
        config.toJson(),
      );
      Logger.info('Start overlay ${config.id}: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to start overlay', _tag, e);
      return Result.failure('启动遮罩失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to start overlay', _tag, e);
      return Result.failure('启动遮罩失败: $e');
    }
  }

  static Future<Result<bool>> stopOverlay(String overlayId) async {
    try {
      final result = await _channel.invokeMethod<bool>('stopOverlay', {
        'id': overlayId,
      });
      Logger.info('Stop overlay $overlayId: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to stop overlay', _tag, e);
      return Result.failure('停止遮罩失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to stop overlay', _tag, e);
      return Result.failure('停止遮罩失败: $e');
    }
  }

  static Future<Result<bool>> updateOverlay(OverlayConfig config) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateOverlay',
        config.toJson(),
      );
      Logger.info('Update overlay ${config.id}: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to update overlay', _tag, e);
      return Result.failure('更新遮罩失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to update overlay', _tag, e);
      return Result.failure('更新遮罩失败: $e');
    }
  }

  static Future<Result<bool>> isOverlayRunning(String overlayId) async {
    try {
      final result = await _channel.invokeMethod<bool>('isOverlayRunning', {
        'id': overlayId,
      });
      Logger.debug('Is overlay $overlayId running: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to check overlay running state', _tag, e);
      return Result.failure('检查遮罩状态失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to check overlay running state', _tag, e);
      return Result.failure('检查遮罩状态失败: $e');
    }
  }

  static Future<Result<List<Map<String, dynamic>>>>
  getRunningOverlayConfigs() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getRunningOverlayConfigs',
      );
      if (result != null) {
        final configs = result
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        Logger.debug('Running overlay configs: ${configs.length}', _tag);
        return Result.success(configs);
      }
      return Result.success([]);
    } on PlatformException catch (e) {
      Logger.error('Failed to get running overlay configs', _tag, e);
      return Result.failure('获取运行中遮罩配置失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to get running overlay configs', _tag, e);
      return Result.failure('获取运行中遮罩配置失败: $e');
    }
  }

  static Future<Result<bool>> ensureOverlaysRestored() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'ensureOverlaysRestored',
      );
      Logger.debug('Ensure overlays restored: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to ensure overlays restored', _tag, e);
      return Result.failure('恢复遮罩失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to ensure overlays restored', _tag, e);
      return Result.failure('恢复遮罩失败: $e');
    }
  }

  static Future<Result<bool>> updateQuickTile() async {
    try {
      final result = await _channel.invokeMethod<bool>('updateQuickTile');
      Logger.debug('Update quick tile: $result', _tag);
      return Result.success(result ?? false);
    } on PlatformException catch (e) {
      Logger.error('Failed to update quick tile', _tag, e);
      return Result.failure('更新快捷开关失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to update quick tile', _tag, e);
      return Result.failure('更新快捷开关失败: $e');
    }
  }

  static Future<Result<Map<String, double>>> getScreenSize() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getScreenSize',
      );
      if (result != null) {
        final size = {
          'width': (result['width'] as num).toDouble(),
          'height': (result['height'] as num).toDouble(),
        };
        Logger.debug('Screen size: $size', _tag);
        return Result.success(size);
      }
      return Result.success({'width': 0.0, 'height': 0.0});
    } on PlatformException catch (e) {
      Logger.error('Failed to get screen size', _tag, e);
      return Result.failure('获取屏幕尺寸失败: ${e.message}');
    } catch (e) {
      Logger.error('Failed to get screen size', _tag, e);
      return Result.failure('获取屏幕尺寸失败: $e');
    }
  }

  static Stream<Map<String, dynamic>>? get overlayEvents {
    try {
      return _eventChannel.receiveBroadcastStream().map((event) {
        if (event is String) {
          return Map<String, dynamic>.from(jsonDecode(event));
        }
        return <String, dynamic>{};
      });
    } catch (e) {
      Logger.error('Failed to get overlay events', _tag, e);
      return null;
    }
  }

  static void Function(bool enabled)? _onGlobalStateChanged;

  static void setGlobalStateChangedHandler(
    void Function(bool enabled) handler,
  ) {
    _onGlobalStateChanged = handler;
  }

  static void setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onGlobalStateChanged') {
        final enabled = call.arguments['enabled'] as bool? ?? false;
        Logger.debug('Global state changed from native: $enabled', _tag);
        _onGlobalStateChanged?.call(enabled);
      }
      return null;
    });
  }
}
