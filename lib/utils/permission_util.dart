import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../widgets/common/toast.dart';
import '../utils/logger.dart';

class PermissionUtil {
  static final PermissionUtil _instance = PermissionUtil._internal();
  factory PermissionUtil() => _instance;
  PermissionUtil._internal();

  // 检查所有权限状态的静态方法
  static Future<void> checkAllPermissions() async {
    AppLogger.debug('开始检查所有权限状态');

    final permissions = [
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.mediaLibrary,
    ];

    for (var permission in permissions) {
      final status = await permission.status;
      AppLogger.debug('权限 ${permission.toString()} 状态: $status');
    }
  }

  // 请求存储权限
  Future<bool> requestStoragePermission(BuildContext context) async {
    // 检查权限状态
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      // 用户永久拒绝了权限
      if (!context.mounted) return false;
      Toast.warning(context, '请在设置中开启存储权限');
      await openAppSettings();
      return false;
    }

    // 请求权限
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  // 请求相册权限
  Future<bool> requestPhotosPermission(BuildContext context) async {
    try {
      AppLogger.debug('PermissionUtil - 开始检查相册权限状态');

      // 获取当前权限状态
      final status = await Permission.storage.status;
      AppLogger.debug('PermissionUtil - 当前存储权限状态: $status');

      // 如果已经授权，直接返回
      if (status.isGranted) {
        AppLogger.debug('PermissionUtil - 存储权限已授权');
        return true;
      }

      // 如果是永久拒绝，提示去设置页面
      if (status.isPermanentlyDenied) {
        AppLogger.debug('PermissionUtil - 存储权限被永久拒绝，需要跳转到设置页面');
        if (!context.mounted) return false;

        final bool? shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要存储权限'),
            content: const Text('请在设置中开启存储权限，以便保存图片'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('去设置'),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          AppLogger.debug('PermissionUtil - 用户选择打开设置页面');
          final settingsOpened = await openAppSettings();
          AppLogger.debug(
              'PermissionUtil - 打开设置页面${settingsOpened ? '成功' : '失败'}');
        }
        return false;
      }

      // 其他情况（首次请求或之前拒绝但未永久拒绝），直接请求权限
      AppLogger.debug('PermissionUtil - 开始请求存储权限');
      try {
        final result = await Permission.storage.request();
        AppLogger.debug('PermissionUtil - 存储权限请求结果: $result');
        return result.isGranted;
      } catch (requestError, requestStack) {
        AppLogger.error(
            'PermissionUtil - 权限请求过程出错', requestError, requestStack);
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('PermissionUtil - 请求存储权限失败', e, stack);
      if (context.mounted) {
        Toast.error(context, '权限请求失败，请重试');
      }
      return false;
    }
  }

  // 请求相机权限
  Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      Toast.warning(context, '请在设置中开启相机权限');
      await openAppSettings();
      return false;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }
}
