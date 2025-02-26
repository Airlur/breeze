import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color? backgroundColor;

  const QRCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QrImageView(
          data: data,
          size: size,
          backgroundColor: backgroundColor ?? Colors.white,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: primaryColor,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '长按二维码可保存图片',
          style: TextStyle(
            color: primaryColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
