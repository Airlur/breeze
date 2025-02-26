import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/file_message.dart';
import '../common/toast.dart';
import 'message_item.dart';

class FileMessageItem extends MessageItem {
  final Function(String)? onDownload;

  const FileMessageItem({
    super.key,
    required FileMessage message,
    super.onDelete,
    super.onShowQr,
    required super.onShowToast,
    this.onDownload,
  }) : super(message: message);

  @override
  Widget buildMessageContent(BuildContext context) {
    final fileMessage = message as FileMessage;

    return InkWell(
      onTap: () => _handleTap(context, fileMessage),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildFileIcon(fileMessage.fileType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileMessage.fileName,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileMessage.formattedFileSize,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!fileMessage.isDownloaded)
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => onDownload?.call(fileMessage.filePath),
                  ),
              ],
            ),
            buildTimeWidget(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(String fileType) {
    IconData iconData;
    Color iconColor;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        iconData = Icons.image;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  void _handleTap(BuildContext context, FileMessage fileMessage) {
    if (fileMessage.isDownloaded) {
      final file = File(fileMessage.filePath);
      if (file.existsSync()) {
        // TODO: 打开文件
        Toast.show(context, '打开文件: ${fileMessage.fileName}');
      } else {
        Toast.show(context, '文件不存在');
      }
    } else {
      onDownload?.call(fileMessage.filePath);
    }
  }
}
