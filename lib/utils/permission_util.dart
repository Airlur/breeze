import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import '../widgets/common/toast.dart';

class PermissionUtil {
  static final PermissionUtil _instance = PermissionUtil._internal();
  factory PermissionUtil() => _instance;
  PermissionUtil._internal();

  /// Log-only helper, does not trigger system prompts.
  static Future<void> checkAllPermissions() async {
    AppLogger.debug('\u5f00\u59cb\u68c0\u67e5\u6240\u6709\u6743\u9650\u72b6\u6001');
    final permissions = [
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.mediaLibrary,
    ];
    for (final permission in permissions) {
      final status = await permission.status;
      AppLogger.debug(
          '\u6743\u9650 ${permission.toString()} \u72b6\u6001: $status');
    }
  }

  Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      Toast.warning(context, '\u8bf7\u5728\u8bbe\u7f6e\u4e2d\u5f00\u542f\u5b58\u50a8\u6743\u9650');
      await openAppSettings();
      return false;
    }

    final result = await Permission.storage.request();
    return result.isGranted;
  }

  Future<bool> requestPhotosPermission(BuildContext context) async {
    try {
      final photoPermission =
          Platform.isIOS ? Permission.photos : Permission.storage;

      var status = await photoPermission.status;
      AppLogger.debug(
          'PermissionUtil - \u5f53\u524d\u76f8\u518c/\u5b58\u50a8\u6743\u9650\u72b6\u6001: $status');

      if (status.isGranted || status.isLimited) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        if (!context.mounted) return false;
        final bool? shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('\u9700\u8981\u76f8\u518c\u6743\u9650'),
            content:
                const Text('\u8bf7\u5728\u8bbe\u7f6e\u4e2d\u5f00\u542f\u76f8\u518c/\u5b58\u50a8\u6743\u9650\uff0c\u4ee5\u4fbf\u4fdd\u5b58\u56fe\u7247'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('\u53d6\u6d88'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('\u53bb\u8bbe\u7f6e'),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
        return false;
      }

      try {
        status = await photoPermission.request();
        AppLogger.debug(
            'PermissionUtil - \u76f8\u518c/\u5b58\u50a8\u6743\u9650\u8bf7\u6c42\u7ed3\u679c: $status');
        return status.isGranted || status.isLimited;
      } catch (requestError, requestStack) {
        AppLogger.error(
            'PermissionUtil - \u6743\u9650\u8bf7\u6c42\u8fc7\u7a0b\u51fa\u9519',
            requestError,
            requestStack);
        return false;
      }
    } catch (e, stack) {
      AppLogger.error(
          'PermissionUtil - \u8bf7\u6c42\u76f8\u518c/\u5b58\u50a8\u6743\u9650\u5931\u8d25',
          e,
          stack);
      if (context.mounted) {
        Toast.error(context, '\u6743\u9650\u8bf7\u6c42\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5');
      }
      return false;
    }
  }

  Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      Toast.warning(context, '\u8bf7\u5728\u8bbe\u7f6e\u4e2d\u5f00\u542f\u76f8\u673a\u6743\u9650');
      await openAppSettings();
      return false;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }
}
