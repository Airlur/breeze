import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../models/file.dart';
import '../../services/local/db_service.dart';
import '../../services/local/storage_service.dart';
import '../../utils/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import '../qr_scan/scan_result_screen.dart';
import 'package:breeze/widgets/common/toast.dart';
import 'dart:async';

class HomeController extends ChangeNotifier {
  final DBService _db;
  final StorageService _storageService;
  double _uploadProgress = 0;
  List<Message> _messages = [];
  List<Message> _filteredMessages = [];
  bool _isLoading = false;
  bool _isSearching = false;
  final String _searchQuery = '';
  Timer? _searchDebounceTimer;

  List<Message> get messages => _isSearching ? _filteredMessages : _messages;
  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;

  HomeController(this._db, this._storageService);

  // 初始化
  Future<void> init() async {
    _setLoading(true);
    try {
      await _loadMessages();
    } finally {
      _setLoading(false);
    }
  }

  // 加载消息
  Future<void> _loadMessages() async {
    if (_searchQuery.isNotEmpty) {
      _messages = await _db.searchMessages(_searchQuery);
    } else {
      _messages = await _db.getAllMessages();
    }
    notifyListeners();
  }

  // 发送文本消息
  Future<void> sendTextMessage(String content) async {
    final deviceId = await _storageService.getDeviceId();
    final message = Message(
      content: content,
      type: 'text',
      senderDeviceId: deviceId,
    );
    await _db.insertMessage(message);
    await _loadMessages();
  }

  // 发送文件消息
  Future<void> sendFileMessage(String filePath) async {
    try {
      // 1. 获取设备ID
      final deviceId = await _storageService.getDeviceId();

      // 2. 获取文件信息
      final file = File(filePath);
      final filename = file.path.split('/').last;
      final size = await file.length();
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

      // 3. 生成文件ID
      final fileId = const Uuid().v4();

      // 4. 创建文件信息
      final fileInfo = FileModel(
        id: fileId,
        filename: filename,
        size: size,
        url: filePath,
        mimeType: mimeType,
        uploadedBy: deviceId,
      );

      // 5. 创建文件消息
      final message = Message(
        content: fileId,
        type: 'file',
        senderDeviceId: deviceId,
      );

      // 6. 保存消息和文件信息
      await Future.wait([
        _db.insertMessage(message),
        _db.insertFile(fileInfo),
      ]);

      // _messages.add(message);
      // notifyListeners();

      await _loadMessages();
    } catch (e) {
      rethrow;
    }
  }

  // 删除消息
  Future<void> deleteMessage(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final message = _messages.firstWhere((msg) => msg.id == id);

      // 如果是文件消息，删除关联的文件
      if (message.type == 'file') {
        final fileInfo = await _db.getFile(message.content);
        if (fileInfo != null) {
          await _storageService.deleteFile(fileInfo.url);
          await _db.deleteFile(fileInfo.id);
        }
      }

      // 删除消息记录
      await _db.deleteMessage(id);
      _messages.removeWhere((msg) => msg.id == id);

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('HomeController - 删除消息失败', e, stackTrace);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 编辑文本消息
  Future<void> editTextMessage(String messageId, String newContent) async {
    final message = _messages.firstWhere((m) => m.id == messageId);
    if (message.type != 'text') {
      throw Exception('只能编辑文本消息');
    }

    final updatedMessage = message.copyWith(
      content: newContent,
      isEdited: true,
    );

    await _db.updateMessage(updatedMessage);
    await _loadMessages();
  }

  // 搜索消息和文件
  void searchMessages(String keyword) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _isSearching = keyword.isNotEmpty;
      if (_isSearching) {
        _filteredMessages = _messages.where((message) {
          final searchText = keyword.toLowerCase();

          switch (message.type) {
            case 'text':
              return message.content.toLowerCase().contains(searchText);
            case 'file':
              return message.content.toLowerCase().contains(searchText);
            default:
              return false;
          }
        }).toList();
      } else {
        _filteredMessages = [];
      }
      notifyListeners();
    });
  }

  // 清除搜索
  void clearSearch() {
    _isSearching = false;
    _filteredMessages = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 获取文件信息
  Future<FileModel?> getFileInfo(String fileId) async {
    try {
      return await _db.getFile(fileId);
    } catch (e) {
      AppLogger.error('获取文件信息失败: $e');
      return null;
    }
  }

  // 处理扫码结果
  Future<void> handleScanResult(String code, BuildContext context) async {
    try {
      // 判断是否是URL
      final Uri? uri = Uri.tryParse(code);
      final bool isUrl = uri?.hasScheme ?? false;

      // 跳转到扫码结果页
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(
              content: code,
              url: isUrl ? code : null,
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('处理扫码结果出错: $e');
      if (context.mounted) {
        Toast.error(context, '处理扫码结果失败');
      }
    }
  }

  void updateUploadProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
