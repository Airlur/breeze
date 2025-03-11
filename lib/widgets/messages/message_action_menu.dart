import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../screens/qr_scan/qr_screen.dart';

class MessageActionMenu extends StatelessWidget {
  final Message message;
  final VoidCallback? onMultiSelect;
  final VoidCallback? onCopy;
  final VoidCallback? onForward;
  final VoidCallback? onDownload;
  final VoidCallback? onGenerateQR;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageActionMenu({
    super.key,
    required this.message,
    this.onMultiSelect,
    this.onCopy,
    this.onForward,
    this.onDownload,
    this.onGenerateQR,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('构建 MessageActionMenu');
    final bool isFileMessage = message.type == 'file';

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(
              icon: Icons.check_circle_outline,
              label: '多选',
              onTap: onMultiSelect,
            ),
            _buildDivider(),
            if (isFileMessage) ...[
              _buildMenuItem(
                icon: Icons.forward,
                label: '转发',
                onTap: onForward,
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.download,
                label: '下载',
                onTap: onDownload,
              ),
            ] else ...[
              _buildMenuItem(
                icon: Icons.content_copy,
                label: '复制',
                onTap: () {
                  debugPrint('点击了复制按钮');
                  onCopy?.call();
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.edit,
                label: '编辑',
                onTap: onEdit,
              ),
            ],
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.qr_code_2,
              label: '生成二维码',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrScreen(
                      content: message.type == 'file'
                          ? 'file://${message.content}'
                          : message.content,
                    ),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.delete,
              label: '删除',
              color: Colors.red,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        debugPrint('点击了菜单项: $label');
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color ?? Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }
}
