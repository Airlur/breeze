import 'package:uuid/uuid.dart';
import 'text_message.dart';
import 'file_message.dart';

abstract class Message {
  final String id;
  final DateTime timestamp;
  bool isDeleted;

  Message({
    String? id,
    DateTime? timestamp,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  // 转换为Map用于数据库存储
  Map<String, dynamic> toMap();

  // 从Map创建消息对象
  factory Message.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    switch (type) {
      case 'text':
        return TextMessage.fromMap(map);
      case 'file':
        return FileMessage.fromMap(map);
      default:
        throw ArgumentError('Unknown message type: $type');
    }
  }

  // 用于生成二维码的数据
  String toQrData();

  // 复制消息
  Message copyWith({
    String? id,
    DateTime? timestamp,
    bool? isDeleted,
  });
}
