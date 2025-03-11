import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../models/file.dart';

abstract class MessageItem extends StatelessWidget {
  final Message message;
  final FileModel? fileInfo; // 可选的文件信息
  final Function(Message)? onDelete;
  final Function(Message)? onShowQr;
  final Function(String) onShowToast;
  final Function(String)? onDownload;

  const MessageItem({
    super.key,
    required this.message,
    this.fileInfo,
    this.onDelete,
    this.onShowQr,
    required this.onShowToast,
    this.onDownload,
  });

  Widget buildMessageContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(message.deviceInitials),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.deviceName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                buildMessageContent(context),
                const SizedBox(height: 4),
                Text(
                  message.formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
