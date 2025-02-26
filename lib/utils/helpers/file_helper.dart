import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../config/constants.dart';
import '../../utils/logger.dart';

class FileHelper {
  static Future<String> getLocalFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'files', fileName);
  }

  static Future<bool> isValidFile(File file) async {
    if (!await file.exists()) return false;

    final size = await file.length();
    if (size > AppConstants.maxFileSize) return false;

    final extension =
        path.extension(file.path).toLowerCase().replaceAll('.', '');
    return AppConstants.supportedFileTypes.contains(extension);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static Future<void> cleanupOldFiles(int daysOld) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filesDir = Directory(path.join(directory.path, 'files'));
      if (!await filesDir.exists()) return;

      final now = DateTime.now();
      await for (final entity in filesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;
          if (age > daysOld) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      AppLogger.error('清理旧文件失败', e);
    }
  }
}
