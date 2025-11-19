import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:breeze/utils/logger.dart';
import 'package:breeze/utils/permission_util.dart';
import 'package:breeze/widgets/common/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrScreen extends StatefulWidget {
  final String content;

  const QrScreen({
    super.key,
    required this.content,
  });

  @override
  State<QrScreen> createState() => _QrScreenState();
}

String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB'];
  int i = (math.log(bytes) / math.log(1024)).floor();
  if (i >= suffixes.length) {
    i = suffixes.length - 1;
  }
  final value = (bytes / math.pow(1024, i)).toStringAsFixed(2);
  return '$value ${suffixes[i]}';
}

class _QrScreenState extends State<QrScreen> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _saveQrCode(BuildContext context) async {
    try {
      if (!context.mounted) return;
      final hasPermission =
          await PermissionUtil().requestPhotosPermission(context);
      if (!hasPermission) return;

      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (!context.mounted) return;
        Toast.error(context, '二维码未绘制完成');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 20));
      final image = await boundary.toImage(pixelRatio: 3.0);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paintBounds = Rect.fromLTWH(0, 0, image.width.toDouble(),
          image.height.toDouble());
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(paintBounds, paint);
      canvas.drawImage(image, Offset.zero, Paint());
      final whiteBgImage =
          await recorder.endRecording().toImage(image.width, image.height);

      final byteData =
          await whiteBgImage.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(
        buffer,
        quality: 100,
        name: 'qr_code_${DateTime.now().millisecondsSinceEpoch}',
      );

      AppLogger.info('二维码图片生成成功，大小: ${formatFileSize(buffer.length)}');

      if (!context.mounted) return;
      if (result['isSuccess']) {
        Toast.success(context, '二维码已保存到相册');
      } else {
        Toast.error(context, '保存失败');
      }
    } catch (e) {
      AppLogger.error('保存二维码失败', e);
      if (!context.mounted) return;
      Toast.error(context, '保存失败：$e');
    }
  }

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
      backgroundColor: const Color(0xFFF6F7FB),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          return Column(
            children: [
              // 二维码卡片 + 内容预览区域占据除按钮外的所有空间
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _buildQrCard(availableWidth - 32),
                      const SizedBox(height: 24),
                      _buildContentPreview(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top:8 ,left: 16, right: 16, bottom: 16),
                child: _buildActionButtons(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQrCard(double availableWidth) {
    final double cardSize = availableWidth;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: RepaintBoundary(
          key: _qrKey,
          child: _buildCardContent(cardSize),
        ),
      ),
    );
  }

  Widget _buildCardContent(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Breeze',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '扫描二维码查看内容',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(14),
              child: Center(
                child: QrImageView(
                  data: widget.content,
                  version: QrVersions.auto,
                  gapless: true,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 限制内容预览区域的最大高度为屏幕的1/3
        final maxHeight = constraints.maxHeight * 0.3;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  const Text(
                    '内容预览',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  minHeight: 80,
                ),
                child: SelectableText(
                  widget.content,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _saveQrCode(context),
              icon: const Icon(Icons.save),
              label: const Text('保存'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
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
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
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
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
