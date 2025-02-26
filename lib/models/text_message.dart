import 'message.dart';

class TextMessage extends Message {
  String content;
  bool isEdited;

  TextMessage({
    super.id,
    super.timestamp,
    super.isDeleted,
    required this.content,
    this.isEdited = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isDeleted': isDeleted ? 1 : 0,
      'content': content,
      'isEdited': isEdited ? 1 : 0,
      'type': 'text',
    };
  }

  static TextMessage fromMap(Map<String, dynamic> map) {
    return TextMessage(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isDeleted: map['isDeleted'] == 1,
      content: map['content'],
      isEdited: map['isEdited'] == 1,
    );
  }

  @override
  String toQrData() {
    return content;
  }

  @override
  TextMessage copyWith({
    String? id,
    DateTime? timestamp,
    bool? isDeleted,
    String? content,
    bool? isEdited,
  }) {
    return TextMessage(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      content: content ?? this.content,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
