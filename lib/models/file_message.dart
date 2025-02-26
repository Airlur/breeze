import 'message.dart';

class FileMessage extends Message {
  String fileName;
  String filePath;
  int fileSize;
  String fileType;
  bool isDownloaded;

  FileMessage({
    super.id,
    super.timestamp,
    super.isDeleted,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    this.isDownloaded = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isDeleted': isDeleted ? 1 : 0,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'fileType': fileType,
      'isDownloaded': isDownloaded ? 1 : 0,
      'type': 'file',
    };
  }

  static FileMessage fromMap(Map<String, dynamic> map) {
    return FileMessage(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isDeleted: map['isDeleted'] == 1,
      fileName: map['fileName'],
      filePath: map['filePath'],
      fileSize: map['fileSize'],
      fileType: map['fileType'],
      isDownloaded: map['isDownloaded'] == 1,
    );
  }

  @override
  String toQrData() {
    return 'file://$filePath';
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  FileMessage copyWith({
    String? id,
    DateTime? timestamp,
    bool? isDeleted,
    String? fileName,
    String? filePath,
    int? fileSize,
    String? fileType,
    bool? isDownloaded,
  }) {
    return FileMessage(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
