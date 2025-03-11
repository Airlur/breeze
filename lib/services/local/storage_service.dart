import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _deviceIdKey = 'device_id';
  static const String _deviceNameKey = 'device_name';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // 检查并请求存储权限
  Future<bool> checkAndRequestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return true; // iOS 不需要显式请求文件权限
  }

  // 获取设备ID
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = await _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  // 获取设备名称
  Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceName = prefs.getString(_deviceNameKey);

    if (deviceName == null) {
      deviceName = await _generateDeviceName();
      await prefs.setString(_deviceNameKey, deviceName);
    }

    return deviceName;
  }

  // 保存文件
  Future<String> saveFile(File file, String filename) async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final path = await _localPath;
      final filePath = '$path/files/$filename';
      final fileDir = Directory('$path/files');

      if (!await fileDir.exists()) {
        await fileDir.create(recursive: true);
      }

      await file.copy(filePath);
      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('StorageService - 保存文件失败', e, stackTrace);
      rethrow;
    }
  }

  // 删除文件
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stackTrace) {
      AppLogger.error('StorageService - 删除文件失败', e, stackTrace);
      rethrow;
    }
  }

  // 获取文件大小
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e, stackTrace) {
      AppLogger.error('获取文件大小失败', e, stackTrace);
      rethrow;
    }
  }

  // 清理过期文件
  Future<void> cleanupOldFiles(Duration maxAge) async {
    try {
      final path = await _localPath;
      final directory = Directory('$path/files');

      if (!await directory.exists()) return;

      final now = DateTime.now();
      await for (final entity in directory.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          if (age > maxAge) {
            await entity.delete();
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('清理过期文件失败', e, stackTrace);
      rethrow;
    }
  }

  // 生成设备ID
  Future<String> _generateDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      AppLogger.error('StorageService - 获取设备ID失败', e);
      // 使用时间戳作为备选设备ID
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }

  // 生成设备名称
  Future<String> _generateDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    return 'Unknown Device';
  }
}
