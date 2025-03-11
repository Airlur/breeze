import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/file.dart';
import 'message_item.dart';
import 'message_action_menu.dart';
import '../../screens/qr_scan/qr_screen.dart';

class FileMessageItem extends MessageItem {
  const FileMessageItem({
    super.key,
    required super.message,
    required FileModel super.fileInfo,
    super.onDelete,
    super.onShowQr,
    required super.onShowToast,
    super.onDownload,
  });

  void _showActionMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) => Stack(
        children: [
          Positioned.fill(
            // 放在下层
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            // 放在上层
            left: 24,
            right: 24,
            top: offset.dy + button.size.height / 2,
            child: MessageActionMenu(
              message: message,
              onMultiSelect: () {
                Navigator.pop(context);
              },
              onForward: () {
                Navigator.pop(context);
                // TODO: 实现转发功能
              },
              onDownload: () {
                Navigator.pop(context);
                final fileInfo = this.fileInfo;
                if (fileInfo != null) {
                  onDownload?.call(fileInfo.url);
                }
              },
              onGenerateQR: () {
                Navigator.pop(context);
                Future.microtask(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrScreen(
                        content: 'file://${fileInfo?.url}',
                      ),
                    ),
                  );
                });
              },
              onDelete: () {
                debugPrint('点击了删除');
                Navigator.pop(context);
                onDelete?.call(message);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildMessageContent(BuildContext context) {
    if (fileInfo == null) {
      return const Text('文件信息不可用');
    }

    return GestureDetector(
      onLongPress: () => _showActionMenu(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            _buildFileIcon(fileInfo!.mimeType),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileInfo!.filename,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatFileSize(fileInfo!.size),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.grey),
              onPressed: () => _handleTap(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildFileIcon(String mimeType) {
    final fileType = mimeType.split('/').last;
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

  void _handleTap(BuildContext context) {
    if (fileInfo == null) return;

    final file = File(fileInfo!.url);
    if (file.existsSync()) {
      // TODO: 打开文件
      onShowToast('打开文件: ${fileInfo!.filename}');
    } else {
      onDownload?.call(fileInfo!.url);
    }
  }
}
