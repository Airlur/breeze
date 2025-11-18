import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'message_item.dart';
import 'message_action_menu.dart';
import '../../screens/qr_scan/qr_screen.dart';
import '../../screens/home/home_controller.dart';
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
    final rootContext = context;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;

    final messageHeight = button.size.height;
    final messageTop = offset.dy;
    final isInUpperHalf = messageTop < screenSize.height / 2;
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
            top: isMessageTooLong
                ? screenSize.height * 0.3
                : isInUpperHalf
                    ? messageTop + messageHeight / 2
                    : null,
            bottom: isMessageTooLong
                ? null
                : isInUpperHalf
                    ? null
                    : screenSize.height - messageTop,
            child: MessageActionMenu(
              message: message,
              onMultiSelect: () {
                Navigator.pop(context);
              },
              onCopy: () async {
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: message.content));
                if (!rootContext.mounted) return;
                Toast.success(rootContext, '已复制到剪贴板');
              },
              onGenerateQR: () {
                Navigator.pop(context);
                Future.microtask(() {
                  if (!rootContext.mounted) return;
                  Navigator.push(
                    rootContext,
                    MaterialPageRoute(
                      builder: (context) => QrScreen(
                        content: message.content,
                      ),
                    ),
                  );
                });
              },
              onEdit: () {
                Navigator.pop(context);
                _showEditDialog(rootContext);
              },
              onDelete: () {
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

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.content);
    // 光标移到末尾，便于直接编辑
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    final focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: '修改后的消息内容',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isEmpty) {
                Toast.warning(context, '内容不能为空');
                return;
              }
              if (newContent == message.content) {
                Navigator.pop(ctx);
                return;
              }
              try {
                await context
                    .read<HomeController>()
                    .editTextMessage(message.id, newContent);
                if (!context.mounted) return;
                Toast.success(context, '消息已更新');
                Navigator.of(context).pop();
              } catch (e) {
                if (!context.mounted) return;
                Toast.error(context, '更新失败: $e');
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
