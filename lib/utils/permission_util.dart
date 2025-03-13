import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../widgets/common/toast.dart';
import '../utils/logger.dart';

class PermissionUtil {
  static final PermissionUtil _instance = PermissionUtil._internal();
  factory PermissionUtil() => _instance;
  PermissionUtil._internal();

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
      final status = await Permission.photos.status;
      AppLogger.debug('PermissionUtil - 当前相册权限状态: $status');

      if (status.isGranted) {
        AppLogger.debug('PermissionUtil - 相册权限已授权');
        return true;
      }

      if (status.isPermanentlyDenied) {
        // 用户在之前的弹窗中选择了"不再询问"
        AppLogger.debug('PermissionUtil - 相册权限被永久拒绝，需要跳转到设置页面');
        if (!context.mounted) return false;
        Toast.warning(context, '需要在设置中手动开启相册权限才能保存图片');
        final result = await openAppSettings();
        AppLogger.debug('PermissionUtil - 打开应用设置页面: $result');
        return false;
      }

      // 首次请求权限或之前点击了拒绝（但没有选择"不再询问"）
      // 这里会触发系统的权限请求弹窗
      AppLogger.debug('PermissionUtil - 请求相册权限');
      final result = await Permission.photos.request();
      AppLogger.debug('PermissionUtil - 相册权限请求结果: $result');

      return result.isGranted;
    } catch (e, stack) {
      AppLogger.error('PermissionUtil - 请求相册权限失败', e, stack);
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
