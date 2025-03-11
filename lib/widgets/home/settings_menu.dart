import 'package:flutter/material.dart';

class SettingsMenu extends StatelessWidget {
  final VoidCallback? onDeviceManage;
  final VoidCallback? onClearMessages;
  final VoidCallback? onFileManage;
  final VoidCallback? onLogout;

  const SettingsMenu({
    super.key,
    this.onDeviceManage,
    this.onClearMessages,
    this.onFileManage,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 192, // 48 * 4
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
              icon: Icons.devices,
              label: '设备管理',
              onTap: onDeviceManage,
            ),
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.delete_sweep,
              label: '清空消息',
              onTap: onClearMessages,
            ),
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.folder,
              label: '文件管理',
              onTap: onFileManage,
            ),
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.logout,
              label: '退出登录',
              color: Colors.red,
              onTap: onLogout,
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
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: color ?? Colors.grey[600],
            ),
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
}
