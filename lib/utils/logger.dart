import 'package:flutter/foundation.dart';

class Logger {
  static const String _tag = 'BurnGuard';

  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] DEBUG: $message');
    }
  }

  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] INFO: $message');
    }
  }

  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] WARNING: $message');
    }
  }

  static void error(String message, [String? tag, Object? error]) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] ERROR: $message');
      if (error != null) {
        debugPrint('[${tag ?? _tag}] ERROR DETAILS: $error');
      }
    }
  }
}
