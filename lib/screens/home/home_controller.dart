import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../models/text_message.dart';
import '../../models/file_message.dart';
import '../../services/local/db_service.dart';
import '../../services/local/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/logger.dart'; // 确保正确导入

class HomeController with ChangeNotifier {
  final DBService _dbService = DBService();
  final StorageService _storageService = StorageService();

  List<Message> _messages = [];
  List<Message> _filteredMessages = [];
  bool _isLoading = false;
  bool _isSearching = false;
  final String _searchQuery = '';

  List<Message> get messages => _isSearching ? _filteredMessages : _messages;
  bool get isLoading => _isLoading;

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
      _messages = await _dbService.searchMessages(_searchQuery);
    } else {
      _messages = await _dbService.getAllMessages();
    }
    notifyListeners();
  }

  // 发送文本消息
  Future<void> sendTextMessage(String content) async {
    final message = TextMessage(content: content);
    await _dbService.insertMessage(message);
    await _loadMessages();
  }

  // 发送文件消息
  Future<void> sendFileMessage(PlatformFile platformFile) async {
    _setLoading(true);
    try {
      if (platformFile.path == null) return;

      final file = File(platformFile.path!);
      final savedPath = await _storageService.saveFile(
        file,
        platformFile.name,
      );

      final message = FileMessage(
        fileName: platformFile.name,
        filePath: savedPath,
        fileSize: platformFile.size,
        fileType: platformFile.extension ?? '',
        isDownloaded: true,
      );

      await _dbService.insertMessage(message);
      await _loadMessages();
    } finally {
      _setLoading(false);
    }
  }

  // 删除消息
  Future<void> deleteMessage(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 查找要删除的消息
      final messageIndex = _messages.indexWhere((msg) => msg.id == id);
      if (messageIndex == -1) {
        throw Exception('消息不存在');
      }
      final message = _messages[messageIndex];

      // 删除数据库记录
      await DBService().deleteMessage(id);

      // 如果是文件消息，删除文件
      if (message is FileMessage) {
        await StorageService().deleteFile(message.filePath);
      }

      // 更新内存中的消息列表
      _messages.removeAt(messageIndex);

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
    final message =
        _messages.firstWhere((m) => m.id == messageId) as TextMessage;
    final updatedMessage = message.copyWith(
      content: newContent,
      isEdited: true,
    );

    await _dbService.updateMessage(updatedMessage);
    await _loadMessages();
  }

  // 搜索消息
  void searchMessages(String query) {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    _filteredMessages = _messages.where((message) {
      if (message is TextMessage) {
        return message.content.toLowerCase().contains(query.toLowerCase());
      } else if (message is FileMessage) {
        return message.fileName.toLowerCase().contains(query.toLowerCase());
      }
      return false;
    }).toList();

    notifyListeners();
  }

  // 清除搜索
  void clearSearch() {
    _isSearching = false;
    _filteredMessages.clear();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 清理资源
  @override
  void dispose() {
    super.dispose();
  }
}
