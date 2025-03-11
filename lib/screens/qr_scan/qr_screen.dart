import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:breeze/widgets/common/toast.dart';

class QrScreen extends StatelessWidget {
  final String content;

  const QrScreen({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('二维码'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.black.withOpacity(0.05),
            height: 1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // 二维码
            Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: content,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 32),
            // 原始内容
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '原始内容',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 复制按钮
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content)).then((_) {
                      Toast.success(context, '已复制到剪贴板');
                    });
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('复制'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
