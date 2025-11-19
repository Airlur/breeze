import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/logger.dart';
import '../../utils/permission_util.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isFlashOn = false;
  // 用于获取顶部顶部按钮容器的Key
  final GlobalKey _topButtonsKey = GlobalKey(); 

  // 扫描线动画
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
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
    // 进入页面时请求相机权限
    Future.microtask(_ensureCameraPermission);
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
              final navigator = Navigator.of(context);
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _scannerController.stop();
                Future.delayed(Duration.zero, () {
                  if (!mounted) return;
                  navigator.pop(barcodes.first.rawValue);
                });
              }
            },
          ),

          // 扫描框
          Center(
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30),
              ),
              child: Stack(
                children: [
                  _buildCorner(true, true),
                  _buildCorner(true, false),
                  _buildCorner(false, true),
                  _buildCorner(false, false),
                  Positioned(
                    top: 256 * _animation.value,
                    child: Container(
                      width: 256,
                      height: 2,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 顶部按钮
          Positioned(
            key: _topButtonsKey,
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

          // 提示文案
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
        final result = await _scannerController.analyzeImage(image.path);

        final capture = result is BarcodeCapture ? result : null;
        final hasBarcode = capture != null && capture.barcodes.isNotEmpty;

        if (!mounted) return;

        if (hasBarcode) {
          Navigator.pop(context, capture.barcodes.first.rawValue);
        } else {
          _showError('未检测到二维码，请选择包含二维码的图片');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('图片处理失败，格式不支持或图片损坏');
      AppLogger.error('图片处理失败', e);
      await _scannerController.start();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    // 获取屏幕尺寸和顶部状态栏高度
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    // 获取顶部按钮容器的高度
    double topButtonsHeight = 0;
    if (_topButtonsKey.currentContext != null) {
      final renderBox = _topButtonsKey.currentContext!.findRenderObject() as RenderBox?;
      topButtonsHeight = renderBox?.size.height ?? 0; // 按钮容器的实际高度
    }

    // 提示框顶部偏移 = 状态栏高度 + 顶部按钮容器高度的2/3
    final topOffset = topPadding + topButtonsHeight * (2/3);

    final overlay = Overlay.of(context);
    // 创建一个临时的OverlayEntry
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: topOffset, // 动态计算偏移量
        left: 16,
        right: 16,
        child: Material( // 确保文本和背景正确渲染
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [ // 加个阴影增强显示
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ),
      ),
    );

    // 添加到Overlay并定时移除
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) entry.remove();
    });
  }

  Future<void> _ensureCameraPermission() async {
    final granted =
        await PermissionUtil().requestCameraPermission(context);
    if (!mounted) return;
    if (!granted) {
      _showError('需要相机权限才能扫码');
      Navigator.pop(context);
    }
  }
}
