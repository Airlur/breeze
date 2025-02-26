import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/message.dart';
import '../../config/constants.dart';
import '../common/custom_dialog.dart';
import '../../utils/logger.dart';

abstract class MessageItem extends StatelessWidget {
  final Message message;
  final VoidCallback? onDelete;
  final VoidCallback? onShowQr;
  final Function(String) onShowToast;

  const MessageItem({
    super.key,
    required this.message,
    this.onDelete,
    this.onShowQr,
    required this.onShowToast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Slidable(
        key: ValueKey(message.id),
        closeOnScroll: true,
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.3,
          children: [
            SlidableAction(
              onPressed: (_) => _handleDelete(context),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '删除',
              flex: 1,
            ),
          ],
        ),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.3,
          children: [
            SlidableAction(
              onPressed: (_) {
                onShowQr?.call();
                Slidable.of(context)?.close();
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.qr_code,
              label: '二维码',
              flex: 1,
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: buildMessageContent(context),
        ),
      ),
    );
  }

  Widget buildMessageContent(BuildContext context);

  Future<void> _handleDelete(BuildContext context) async {
    try {
      final BuildContext currentContext = context;
  
      final confirm = await CustomDialog.show(
        context: currentContext,
        title: '删除确认',
        message: AppConstants.tipDeleteConfirm,
        confirmText: '删除',
        cancelText: '取消',
      );

      if (confirm == true && currentContext.mounted) {
        // 等待删除操作完成
        await Future(() => onDelete?.call());

        if (currentContext.mounted) {
          Slidable.of(currentContext)?.close();
          onShowToast(AppConstants.tipDeleteSuccess);
        }
      } else {
        AppLogger.debug('用户取消删除操作');
      }
    } catch (e, stackTrace) {
      AppLogger.error('删除操作发生异常', e, stackTrace);
      onShowToast('删除失败：$e');
    }
  }

  Widget buildTimeWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        _formatTime(message.timestamp),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black38,
            ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
