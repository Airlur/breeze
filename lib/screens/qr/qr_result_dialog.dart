import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/common/toast.dart';

class QRResultDialog extends StatelessWidget {
  final String result;

  const QRResultDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('扫描结果'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '扫描内容：',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: result));
            Toast.show(context, '复制成功');
          },
          child: const Text('复制'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  static Future<void> show(BuildContext context, String result) {
    return showDialog(
      context: context,
      builder: (context) => QRResultDialog(result: result),
    );
  }
}
