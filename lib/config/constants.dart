class AppConstants {
  // 消息相关
  static const int messageTimeThreshold = 30; // 消息时间显示阈值（分钟）
  static const int maxFileSize = 100 * 1024 * 1024; // 最大文件大小限制（100MB）

  // 动画时长
  static const int toastDuration = 2000; // Toast显示时长（毫秒）
  static const int animationDuration = 300; // 一般动画时长（毫秒）

  // 本地存储键
  static const String dbName = 'breeze.db';
  static const String messageTable = 'messages';
  static const String fileTable = 'files';

  // 文件相关
  static const List<String> supportedFileTypes = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'txt',
    'png',
    'jpg',
    'jpeg',
    'gif'
  ];

  // 错误提示文本
  static const String errorFileTooBig = '文件大小超过限制';
  static const String errorFileTypeNotSupported = '不支持的文件类型';
  static const String errorNetworkNotAvailable = '网络连接不可用';

  // 操作提示文本
  static const String tipCopySuccess = '复制成功';
  static const String tipDeleteSuccess = '删除成功';
  static const String tipDeleteConfirm = '确定要删除这条消息吗？';
  static const String tipSaveSuccess = '保存成功';
}
