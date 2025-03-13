import 'package:uuid/uuid.dart';
import '../services/local/storage_service.dart';
import '../services/local/db_service.dart';

class Message {
  static final Map<String, String> _deviceNameCache = {};
  final StorageService _storageService = StorageService();
  final DBService _db = DBService();

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
    final now = DateTime.now();

    // 如果是今天的消息，只显示时间
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // 如果是昨天的消息
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // 如果是今年的消息
    if (date.year == now.year) {
      return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // 其他情况显示完整日期
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 获取设备名称（带缓存）
  Future<String> get deviceName async {
    // 先检查缓存
    if (_deviceNameCache.containsKey(senderDeviceId)) {
      return _deviceNameCache[senderDeviceId]!;
    }

    // 如果是当前设备的消息
    final currentDeviceId = await _storageService.getDeviceId();
    if (senderDeviceId == currentDeviceId) {
      final name = await _storageService.getDeviceName();
      _deviceNameCache[senderDeviceId] = name;
      return name;
    }

    // 其他设备的消息，从数据库查询
    final device = await _db.getDevice(senderDeviceId);
    final name = device?.deviceName ?? senderDeviceId;
    _deviceNameCache[senderDeviceId] = name;
    
    return name;
  }

  // 获取设备缩写（也需要是异步的）
  Future<String> get deviceInitials async {
    final name = await deviceName;
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
