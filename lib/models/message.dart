import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String content; // 消息内容或文件消息的file_id
  final String type; // 消息类型 (text/file)
  final String senderDeviceId; // 发送设备ID
  final int timestamp; // 发送时间戳
  final bool isEncrypted; // 是否加密
  final bool isEdited; // 是否编辑过
  final bool isDeleted; // 是否删除
  final DateTime createdAt; // 创建时间

  Message({
    String? id,
    required this.content,
    required this.type,
    required this.senderDeviceId,
    DateTime? timestamp,
    this.isEncrypted = false,
    this.isEdited = false,
    this.isDeleted = false,
    DateTime? createdAt,
  })  : assert(type == 'text' || type == 'file', 'Invalid message type'),
        id = id ?? const Uuid().v4(),
        timestamp = (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
        createdAt = createdAt ?? DateTime.now();

  // 格式化时间
  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 获取设备名称
  String get deviceName {
    // 根据设备ID查设备表获取设备名称返回
    return senderDeviceId;
  }

  // 获取设备缩写
  String get deviceInitials {
    final name = deviceName;
    if (name.isEmpty) return '';
    final initials = name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .take(2)
        .join();
    return initials.isEmpty ? name[0].toUpperCase() : initials;
  }

  // 转换为Map用于数据库存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type,
      'sender_device_id': senderDeviceId,
      'timestamp': timestamp,
      'is_encrypted': isEncrypted ? 1 : 0,
      'is_edited': isEdited ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 从Map创建消息对象
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String?,
      content: map['content'] as String,
      type: map['type'] as String,
      senderDeviceId: map['sender_device_id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isEncrypted: map['is_encrypted'] == 1,
      isEdited: map['is_edited'] == 1,
      isDeleted: map['is_deleted'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // 用于生成二维码的数据
  String toQrData() {
    return '$type:$id';
  }

  // 复制消息
  Message copyWith({
    String? id,
    String? content,
    String? type,
    String? senderDeviceId,
    int? timestamp,
    bool? isEncrypted,
    bool? isEdited,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      timestamp: timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : DateTime.fromMillisecondsSinceEpoch(this.timestamp),
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
