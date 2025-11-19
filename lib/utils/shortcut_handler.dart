import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'logger.dart';

class ShortcutHandler {
  ShortcutHandler._();
  static final ShortcutHandler instance = ShortcutHandler._();
  final MethodChannel _channel = const MethodChannel('breeze/shortcuts');
  bool _initialized = false;
  VoidCallback? _openScanCallback;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init(VoidCallback openScan) async {
    if (!_isAndroid) return;

    _openScanCallback = openScan;
    if (!_initialized) {
      _initialized = true;
      _channel.setMethodCallHandler(_handleMethodCall);
    }

    try {
      final shortcutId = await _channel.invokeMethod<String>('getShortcut');
      if (shortcutId != null) {
        _dispatch(shortcutId);
      }
    } on MissingPluginException {
      AppLogger.warning('当前平台不支持快捷方式 MethodChannel');
    } on PlatformException catch (e) {
      AppLogger.error('初始化快捷方式通道失败', e);
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'shortcutTriggered') {
      final shortcut = call.arguments as String?;
      if (shortcut != null) {
        _dispatch(shortcut);
      }
    }
    return null;
  }

  void _dispatch(String shortcutId) {
    if (shortcutId == 'scan' || shortcutId == 'scan_shortcut') {
      _openScanCallback?.call();
    } else {
      AppLogger.debug('收到未知快捷方式: $shortcutId');
    }
  }
}
