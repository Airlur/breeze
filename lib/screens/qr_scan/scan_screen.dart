import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/logger.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isFlashOn = false;

  // 添加动画控制器
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 初始化动画
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.repeat();
        }
      });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 扫描预览
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              // 确保只处理一次扫码结果
              if (barcodes.isNotEmpty &&
                  barcodes.first.rawValue != null &&
                  mounted) {
                // 先停止扫描
                _scannerController.stop();
                // 使用 Future.delayed 确保扫描器完全停止后再处理结果
                Future.delayed(Duration.zero, () {
                  if (mounted) {
                    Navigator.pop(context, barcodes.first.rawValue);
                  }
                });
              }
            },
          ),

          // 扫描框UI
          Center(
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30),
              ),
              child: Stack(
                children: [
                  // 四角标记
                  _buildCorner(true, true),
                  _buildCorner(true, false),
                  _buildCorner(false, true),
                  _buildCorner(false, false),

                  // 扫描线
                  Positioned(
                    top: 256 * _animation.value,
                    child: Container(
                      width: 256,
                      height: 2,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 顶部按钮
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white70,
                      ),
                      onPressed: () async {
                        await _scannerController.toggleTorch();
                        setState(() {
                          _isFlashOn = !_isFlashOn;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 提示文字
          const Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Text(
              '将二维码放入框内，即可自动扫描',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ),

          // 底部按钮
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('打开相册'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _pickImage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Positioned(
      top: isTop ? 0 : null,
      bottom: !isTop ? 0 : null,
      left: isLeft ? 0 : null,
      right: !isLeft ? 0 : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await _scannerController.stop();
        final bool hasBarcode =
            await _scannerController.analyzeImage(image.path);

        if (!hasBarcode) {
          _showError('未检测到二维码');
          await _scannerController.start();
        }
      }
    } catch (e) {
      _showError('图片处理失败');
      AppLogger.error('图片处理失败', e);
      await _scannerController.start();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
