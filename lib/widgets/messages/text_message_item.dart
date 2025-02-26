import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/text_message.dart';
import '../common/toast.dart';
import 'message_item.dart';

class TextMessageItem extends MessageItem {
  final Function(String)? onEdit;

  const TextMessageItem({
    super.key,
    required TextMessage message,
    super.onDelete,
    super.onShowQr,
    required super.onShowToast,
    this.onEdit,
  }) : super(message: message);

  @override
  Widget buildMessageContent(BuildContext context) {
    final textMessage = message as TextMessage;

    return InkWell(
      onDoubleTap: () => _handleCopy(context, textMessage.content),
      onLongPress: () => _handleEdit(context, textMessage),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              textMessage.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (textMessage.isEdited)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '(已编辑)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                ),
              ),
            buildTimeWidget(context),
          ],
        ),
      ),
    );
  }

  void _handleCopy(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    Toast.show(context, '复制成功');
  }

  void _handleEdit(BuildContext context, TextMessage textMessage) {
    if (onEdit != null) {
      showDialog(
        context: context,
        builder: (context) => _EditDialog(
          initialText: textMessage.content,
          onConfirm: onEdit!,
        ),
      );
    }
  }
}

class _EditDialog extends StatefulWidget {
  final String initialText;
  final Function(String) onConfirm;

  const _EditDialog({
    required this.initialText,
    required this.onConfirm,
  });

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑消息'),
      content: TextField(
        controller: _controller,
        maxLines: null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final newText = _controller.text.trim();
            if (newText.isNotEmpty) {
              widget.onConfirm(newText);
              Navigator.pop(context);
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
