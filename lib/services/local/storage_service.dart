import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/logger.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

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

  // 保存文件
  Future<String> saveFile(File file, String fileName) async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final path = await _localPath;
      final filePath = '$path/files/$fileName';
      final fileDir = Directory('$path/files');

      if (!await fileDir.exists()) {
        await fileDir.create(recursive: true);
      }

      await file.copy(filePath);
      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('保存文件失败', e, stackTrace);
      rethrow;
    }
  }

  // 删除文件
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stackTrace) {
      AppLogger.error('删除文件失败', e, stackTrace);
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
}
