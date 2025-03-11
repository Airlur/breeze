import 'package:flutter/material.dart';
import 'message_item.dart';
import 'message_action_menu.dart';
import 'package:flutter/services.dart';
import '../../screens/qr_scan/qr_screen.dart';
import 'package:breeze/widgets/common/toast.dart';

class TextMessageItem extends MessageItem {
  const TextMessageItem({
    super.key,
    required super.message,
    required super.onShowToast,
    super.onDelete,
    super.onShowQr,
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
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: offset.dy + button.size.height / 2,
            child: MessageActionMenu(
              message: message,
              onMultiSelect: () {
                Navigator.pop(context);
              },
              onCopy: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content))
                    .then((_) {
                  Toast.success(context, '已复制到剪贴板');
                });
              },
              onGenerateQR: () {
                Navigator.pop(context);
                Future.microtask(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrScreen(
                        content: message.content,
                      ),
                    ),
                  );
                });
              },
              onEdit: () {
                debugPrint('点击了编辑');
                Navigator.pop(context);
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
        child: Text(
          message.content,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
