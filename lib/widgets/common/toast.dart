import 'package:flutter/material.dart';

enum ToastType {
  success,
  error,
  warning,
}

class Toast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);

    // 根据类型设置颜色
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData defaultIcon;

    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        iconColor = Colors.green.shade500;
        textColor = Colors.green.shade600;
        defaultIcon = Icons.check_circle;
      case ToastType.error:
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        iconColor = Colors.red.shade500;
        textColor = Colors.red.shade600;
        defaultIcon = Icons.error;
      case ToastType.warning:
        backgroundColor = Colors.yellow.shade50;
        borderColor = Colors.yellow.shade200;
        iconColor = Colors.yellow.shade500;
        textColor = Colors.yellow.shade600;
        defaultIcon = Icons.warning;
    }

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon ?? defaultIcon,
                  color: iconColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  // 便捷方法
  static void success(BuildContext context, String message, {IconData? icon}) {
    show(context, message, type: ToastType.success, icon: icon);
  }

  static void error(BuildContext context, String message, {IconData? icon}) {
    show(context, message, type: ToastType.error, icon: icon);
  }

  static void warning(BuildContext context, String message, {IconData? icon}) {
    show(context, message, type: ToastType.warning, icon: icon);
  }
}
