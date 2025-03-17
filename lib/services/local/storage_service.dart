import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';
import '../../models/device.dart';
import './db_service.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _deviceIdKey = 'device_id';
  static const String _deviceNameKey = 'device_name';
  final DBService _db = DBService();

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

    // 清理后需要重新生成设备名称
    if (await _db.getDevice(await getDeviceId()) == null) {
      deviceName = await _generateDeviceName();
      await prefs.setString(_deviceNameKey, deviceName);
    }

    return deviceName;
  }

  // 清理本机设备记录（用于开发测试）
  Future<void> cleanLocalDevice() async {
    try {
      final deviceId = await getDeviceId();
      // 清理 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceNameKey);

      // 清理数据库中的所有匹配记录
      final devices = await _db.getAllDevices();
      for (var device in devices) {
        if (device.deviceId == deviceId) {
          await _db.deleteDevice(device.id);
          AppLogger.info('清理设备记录成功: $device');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('清理设备记录失败', e, stackTrace);
      rethrow;
    }
  }

  // 初始化本机设备信息
  Future<void> initLocalDevice() async {
    try {
      final deviceId = await getDeviceId();
      final deviceName = await getDeviceName();

      // 先查询是否已存在设备记录
      final existingDevice = await _db.getDevice(deviceId);
      if (existingDevice != null) {
        // 如果存在，更新最后活动时间
        final updatedDevice = Device(
          id: existingDevice.id,
          deviceId: existingDevice.deviceId,
          deviceName: existingDevice.deviceName,
          deviceType: existingDevice.deviceType,
          isMaster: existingDevice.isMaster,
          lastActive: DateTime.now(), // 更新最后活动时间
          createdAt: existingDevice.createdAt,
        );
        await _db.insertDevice(updatedDevice);
        AppLogger.info('更新设备信息: $updatedDevice');
      } else {
        // 如果不存在，创建新记录
        final newDevice = Device(
          id: const Uuid().v4(),
          deviceId: deviceId,
          deviceName: deviceName,
          deviceType: Platform.isAndroid ? 'android' : 'ios',
          isMaster: true,
          lastActive: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await _db.insertDevice(newDevice);
        AppLogger.info('初始化设备信息: $newDevice');
      }
    } catch (e, stackTrace) {
      AppLogger.error('初始化设备信息失败', e, stackTrace);
      rethrow;
    }
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
      AppLogger.info(
          '设备信息: brand=${androidInfo.brand}, model=${androidInfo.model}, '
          'manufacturer=${androidInfo.manufacturer}, product=${androidInfo.product}, '
          'device=${androidInfo.device}, display=${androidInfo.display}');

      try {
        // 尝试使用 Process.run 获取额外的系统属性
        final result = await Process.run('getprop', ['ro.product.marketname']);
        final marketName = result.stdout.toString().trim();
        
        if (marketName.isNotEmpty) {
          AppLogger.debug('获取到营销名称: $marketName');
          
          // 返回品牌名+营销名称
          return '${androidInfo.manufacturer} $marketName';
        }
        
        // 如果获取不到营销名称，尝试其他属性
        final modelResult = await Process.run('getprop', ['ro.product.model']);
        final modelName = modelResult.stdout.toString().trim();
        
        if (modelName.isNotEmpty) {
          AppLogger.debug('获取到型号名称: $modelName');
          
          // 返回品牌名+型号名称
          return '${androidInfo.manufacturer} $modelName';
        }
      } catch (e) {
        AppLogger.error('获取系统属性失败: $e');
      }

    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    return '未知设备';
  }
}
