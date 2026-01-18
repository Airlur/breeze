import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../utils/logger.dart';
import '../../utils/permission_util.dart';
import '../../utils/mlkit_utils.dart';
import 'ocr_crop_screen.dart'; // 引入新页面

enum ScanMode { qrCode, ocr }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  ScanMode _scanMode = ScanMode.qrCode;
  
  // 统一使用 CameraController
  CameraController? _cameraController;
  CameraDescription? _camera;
  
  // 识别器
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  
  // 状态锁
  bool _isStreamingFrame = false; // 后台流处理锁（不影响UI）
  bool _isCapturing = false;      // 前台拍照锁（控制UI loading）
  
  bool _isFlashOn = false;
  final GlobalKey _topButtonsKey = GlobalKey();

  // 扫描线动画
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    Future.microtask(_ensureCameraPermission);
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.repeat();
        }
      });

    _animationController.forward();
  }

  Future<void> _initCameraController() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('未检测到相机设备');
        return;
      }

      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.veryHigh, // 提升分辨率
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      
      // 启动实时流处理
      await _cameraController!.startImageStream(_processCameraImage);
      
      if (mounted) setState(() {});
    } catch (e) {
      AppLogger.error('相机初始化失败', e);
      _showError('相机初始化失败: $e');
    }
  }

  // 核心：实时图像处理流
  Future<void> _processCameraImage(CameraImage image) async {
    // 如果正在拍照(_isCapturing)或者流正在处理中(_isStreamingFrame)，则跳过
    if (_isCapturing || _isStreamingFrame || _cameraController == null || _camera == null) return;
    _isStreamingFrame = true;

    try {
      final inputImage = MLKitUtils.convertCameraImage(image, _camera!);
      if (inputImage == null) {
        _isStreamingFrame = false;
        return;
      }

      if (_scanMode == ScanMode.qrCode) {
        final barcodes = await _barcodeScanner.processImage(inputImage);
        if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
          if (!mounted) return;
          // 停止流，避免多次触发
          await _cameraController?.stopImageStream(); 
          Navigator.pop(context, barcodes.first.rawValue);
        }
      } 
      // OCR 模式不自动触发
      
    } catch (e) {
      AppLogger.error('图像识别出错', e);
    } finally {
      _isStreamingFrame = false;
    }
  }

  Future<void> _disposeCameraController() async {
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      await _cameraController!.dispose();
      _cameraController = null;
    }
  }

  // 切换模式不再需要销毁相机，只需要切换状态和动画
  Future<void> _switchMode(ScanMode mode) async {
    if (_scanMode == mode) return;
    
    setState(() {
      _scanMode = mode;
    });

    if (mode == ScanMode.qrCode) {
      _animationController.forward();
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _disposeCameraController();
    _textRecognizer.close();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 0) {
            _switchMode(ScanMode.qrCode);
          } else if (details.primaryVelocity! < 0) {
            _switchMode(ScanMode.ocr);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // 1. 统一的相机预览层
            _buildCameraPreview(),

            // 2. 扫描覆盖层
            if (_scanMode == ScanMode.qrCode)
              _buildQrOverlay()
            else
              _buildOcrOverlay(),

            // 3. 顶部操作栏
            _buildTopBar(),

            // 4. 底部操作栏
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildQrOverlay() {
    return Center(
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
    );
  }

  Widget _buildOcrOverlay() {
    return const SizedBox();
  }

  Widget _buildTopBar() {
    return Positioned(
      key: _topButtonsKey,
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeBtn('扫码', ScanMode.qrCode),
                        _buildModeBtn('识字', ScanMode.ocr),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBtn(String label, ScanMode mode) {
    final isSelected = _scanMode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: _scanMode == ScanMode.qrCode
              ? _buildQrBottomBtn()
              : _buildOcrBottomBtn(),
        ),
      ),
    );
  }

  Widget _buildQrBottomBtn() {
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.photo_library),
        label: const Text('从相册选取二维码'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white24,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: _pickImageForQr,
      ),
    );
  }

  Widget _buildOcrBottomBtn() {
    return Center(
      child: GestureDetector(
        onTap: _isCapturing ? null : _captureAndRecognizeText,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            color: Colors.white24,
          ),
          child: _isCapturing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.camera_alt, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  // ... 辅助方法 ...
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

  Future<void> _toggleFlash() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final mode = _isFlashOn ? FlashMode.off : FlashMode.torch;
        await _cameraController!.setFlashMode(mode);
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (e) {
      AppLogger.error('闪光灯切换失败', e);
    }
  }

  Future<void> _pickImageForQr() async {
    // 暂停流处理，防止冲突
    await _cameraController?.stopImageStream();
    
     try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final inputImage = InputImage.fromFilePath(image.path);
        final barcodes = await _barcodeScanner.processImage(inputImage);

        if (!mounted) return;

        if (barcodes.isNotEmpty) {
          Navigator.pop(context, barcodes.first.rawValue);
        } else {
          _showError('未检测到二维码');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('图片处理失败');
    } finally {
      // 恢复流处理
      if (mounted && _cameraController != null) {
         await _cameraController!.startImageStream(_processCameraImage);
      }
    }
  }

  Future<void> _captureAndRecognizeText() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      // 1. 彻底暂停流处理和预览
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      // 关键：暂停预览，释放 GPU/Surface 资源
      await _cameraController!.pausePreview();
      
      // 2. 拍照
      final XFile file = await _cameraController!.takePicture();
      
      if (!mounted) return;
      setState(() => _isCapturing = false);

      // 3. 跳转到裁剪编辑页
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OcrCropScreen(imagePath: file.path)),
      );
      
      // 4. 页面返回后恢复
      if (mounted && _cameraController != null) {
        // 先恢复预览
        await _cameraController!.resumePreview();
        // 再恢复流
        await _cameraController!.startImageStream(_processCameraImage);
      }

    } catch (e) {
      AppLogger.error('拍照失败', e);
      if (mounted) {
        try {
           // 尝试恢复
           if (_cameraController != null) {
             await _cameraController!.resumePreview();
             if (!_cameraController!.value.isStreamingImages) {
                await _cameraController!.startImageStream(_processCameraImage);
             }
           }
        } catch (_) {}

        setState(() => _isCapturing = false);
        _showError('拍照失败，请重试');
      }
    }
  }

  void _showOcrResult(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('识别结果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制全部内容')),
                      );
                    },
                    child: const Text('复制全部'),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    text,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
     if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _ensureCameraPermission() async {
    final granted = await PermissionUtil().requestCameraPermission(context);
    if (!mounted) return;
    if (!granted) {
      _showError('需要相机权限才能扫码');
      Navigator.pop(context);
    } else {
      _initCameraController();
    }
  }
}
