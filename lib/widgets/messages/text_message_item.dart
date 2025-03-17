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
    final Size screenSize = MediaQuery.of(context).size;

    // 获取消息的尺寸
    final messageHeight = button.size.height;
    final messageTop = offset.dy;

    // 判断消息是否在屏幕上半部分
    final isInUpperHalf = messageTop < screenSize.height / 2;

    // 判断消息是否太长（超过屏幕高度的70%）
    final isMessageTooLong = messageHeight > screenSize.height * 0.7;

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
            // 根据条件决定菜单位置
            top: isMessageTooLong
                ? screenSize.height * 0.3 // 如果消息太长，固定在屏幕中上部
                : isInUpperHalf
                    ? messageTop + messageHeight / 2 // 如果在上半部分，显示在消息下方
                    : null, // 如果在下半部分，使用 bottom 定位
            bottom: isMessageTooLong
                ? null
                : isInUpperHalf
                    ? null // 如果在上半部分，不需要 bottom
                    : screenSize.height - messageTop, // 如果在下半部分，显示在消息上方
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
