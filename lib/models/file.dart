class FileModel {
  final String id;
  final String url;
  final String filename;
  final int size;
  final String mimeType;
  final String uploadedBy;
  final DateTime createdAt;

  FileModel({
    required this.id,
    required this.url,
    required this.filename,
    required this.size,
    required this.mimeType,
    required this.uploadedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'size': size,
      'mime_type': mimeType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      id: map['id'] as String,
      url: map['url'] as String,
      filename: map['filename'] as String,
      size: map['size'] as int,
      mimeType: map['mime_type'] as String,
      uploadedBy: map['uploaded_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
