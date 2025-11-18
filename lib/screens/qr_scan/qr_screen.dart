import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:breeze/widgets/common/toast.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:breeze/utils/permission_util.dart';
import 'package:breeze/utils/logger.dart';

class QrScreen extends StatefulWidget {
  final String content;

  const QrScreen({
    super.key,
    required this.content,
  });

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final GlobalKey _qrKey = GlobalKey();

  // 保存二维码到相册
  Future<void> _saveQrCode(BuildContext context) async {
    try {
      if (!context.mounted) return;

      // 请求相册权限
      final hasPermission =
          await PermissionUtil().requestPhotosPermission(context);
      if (!hasPermission) return;

      AppLogger.info('开始生成二维码图片...');
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      AppLogger.info('二维码图片生成成功，大小: ${buffer.length} bytes');

      // 保存到相册
      AppLogger.info('开始保存到相册...');
      final result = await ImageGallerySaverPlus.saveImage(
        buffer,
        quality: 100,
        name: 'qr_code_${DateTime.now().millisecondsSinceEpoch}',
      );
      AppLogger.info('保存结果: $result');

      if (!context.mounted) return;
      if (result['isSuccess']) {
        final filePath = result['filePath'];
        AppLogger.info('保存成功，文件路径: $filePath');
        Toast.success(context, '二维码已保存到相册');
      } else {
        AppLogger.error('保存失败: ${result['error']}');
        Toast.error(context, '保存失败');
      }
    } catch (e) {
      AppLogger.error('发生错误: $e');
      if (!context.mounted) return;
      Toast.error(context, '保存失败：$e');
    }
  }

  // 分享二维码
  Future<void> _shareQrCode(BuildContext context) async {
    try {
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: widget.content,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Toast.error(context, '分享失败：$e');
    }
  }

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
            color: Colors.black.withValues(alpha: 0.05),
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
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: widget.content,
                  version: QrVersions.auto,
                  size: 200,
                ),
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
              child: SelectableText.rich(
                // 使用 SelectableText 来控制文本选择
                TextSpan(
                  children: [
                    TextSpan(
                      text: '原始内容\n',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextSpan(
                      text: widget.content,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // 操作按钮
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _saveQrCode(context),
                      icon: const Icon(Icons.save),
                      label: const Text('保存'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _shareQrCode(context),
                      icon: const Icon(Icons.share),
                      label: const Text('分享'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.content)).then((_) {
                          if (!context.mounted) return;
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
