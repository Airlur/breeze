import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class OcrCropScreen extends StatefulWidget {
  final String imagePath;

  const OcrCropScreen({super.key, required this.imagePath});

  @override
  State<OcrCropScreen> createState() => _OcrCropScreenState();
}

class _OcrCropScreenState extends State<OcrCropScreen> {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  
  File? _imageFile;
  ui.Image? _loadedImage;
  bool _isImageLoaded = false;
  
  // 裁剪区域 (相对于**图片实际显示区域**的归一化坐标 0.0 ~ 1.0)
  Rect _cropRect = const Rect.fromLTWH(0.1, 0.3, 0.8, 0.3);
  
  // 图片在屏幕上的实际渲染区域 (用于限制裁剪框活动范围)
  Rect _imageDisplayRect = Rect.zero;
  
  Timer? _debounceTimer;
  bool _isRecognizing = false;
  String _ocrResultText = "";
  
  // 底部面板高度控制
  double _panelHeight = 120.0;
  final double _minPanelHeight = 120.0;
  final double _maxPanelHeight = 400.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    _imageFile = File(widget.imagePath);
    final data = await _imageFile!.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    
    if (mounted) {
      setState(() {
        _loadedImage = frame.image;
        _isImageLoaded = true;
      });
      // 这里的自动识别延迟到 layout 计算完 _imageDisplayRect 后再触发会更安全
      // 但 _performCropAndOcr 内部有空检查，所以先挂着也没事
      // 实际上最好是在 build 完一次拿到尺寸后再触发。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAutoRecognize();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 使用 Column 分割，避免遮挡
      body: Column(
        children: [
          // 1. 上半部分：图片与裁剪区
          Expanded(
            child: Stack(
              children: [
                // 顶部栏 (浮在图片上)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          if (_isRecognizing)
                            const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 图片区域 LayoutBuilder
                if (_isImageLoaded)
                  Positioned.fill(
                    top: 60, // 让出顶部栏高度
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 关键：计算图片在容器中的实际位置 (BoxFit.contain)
                        _calculateImageRect(constraints.biggest);
                        
                        return Stack(
                          children: [
                            // 底图
                            Positioned.fromRect(
                              rect: _imageDisplayRect,
                              child: Image.file(_imageFile!, fit: BoxFit.fill), // 此时 rect 已经是计算好的，用 fill 填满 rect 即可
                            ),
                            
                            // 裁剪层 (限制在 _imageDisplayRect 内)
                            Positioned.fromRect(
                              rect: _imageDisplayRect,
                              child: CropBox(
                                initialRect: _cropRect,
                                containerSize: _imageDisplayRect.size,
                                onRectUpdate: (val) {
                                  // 这里只更新数据，不 setState 重绘父组件，提升性能
                                  _cropRect = val;
                                },
                                onInteractionEnd: () {
                                  // 拖动结束才触发识别
                                  _triggerAutoRecognize();
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                // 空状态提示
                if (_ocrResultText.isEmpty && !_isRecognizing)
                   const Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: Center(child: Text("拖动选区以识别文字", style: TextStyle(color: Colors.white70, shadows: [Shadow(blurRadius: 2, color: Colors.black)]))),
                  ),
              ],
            ),
          ),
          
          // 2. 下半部分：结果面板 (可调整高度)
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _panelHeight -= details.delta.dy;
                _panelHeight = _panelHeight.clamp(_minPanelHeight, _maxPanelHeight);
              });
            },
            child: Container(
              height: _panelHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black45)],
              ),
              child: Column(
                children: [
                  // 拖拽把手
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  
                  // 标题栏
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_ocrResultText.isEmpty ? '等待识别...' : '识别结果', 
                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        if (_ocrResultText.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _ocrResultText));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
                            },
                            child: const Icon(Icons.copy, size: 20, color: Colors.blue),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // 内容区
                  Expanded(
                    child: _ocrResultText.isEmpty 
                      ? const Center(child: Text("点击或拖动上方图片", style: TextStyle(color: Colors.grey)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(_ocrResultText, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 核心算法：计算 BoxFit.contain 后的实际图片区域
  void _calculateImageRect(Size containerSize) {
    if (_loadedImage == null) return;
    
    final double imgAspectRatio = _loadedImage!.width / _loadedImage!.height;
    final double containerAspectRatio = containerSize.width / containerSize.height;
    
    double displayW, displayH;
    
    if (containerAspectRatio > imgAspectRatio) {
      // 容器更宽，图片高度填满，宽度留黑边
      displayH = containerSize.height;
      displayW = displayH * imgAspectRatio;
    } else {
      // 容器更高，图片宽度填满，高度留黑边
      displayW = containerSize.width;
      displayH = displayW / imgAspectRatio;
    }
    
    final double offsetX = (containerSize.width - displayW) / 2;
    final double offsetY = (containerSize.height - displayH) / 2;
    
    _imageDisplayRect = Rect.fromLTWH(offsetX, offsetY, displayW, displayH);
  }

  void _triggerAutoRecognize() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _performCropAndOcr();
    });
  }

  Future<void> _performCropAndOcr() async {
    if (_loadedImage == null || _isRecognizing) return;
    setState(() => _isRecognizing = true);

    try {
      // 1. 坐标映射 (现在非常简单，因为 CropBox 是完全覆盖在 ImageDisplayRect 上的)
      // _cropRect 是 0~1 的归一化坐标，直接乘原图尺寸即可
      final int imgW = _loadedImage!.width;
      final int imgH = _loadedImage!.height;
      
      final int cropX = (_cropRect.left * imgW).toInt().clamp(0, imgW);
      final int cropY = (_cropRect.top * imgH).toInt().clamp(0, imgH);
      final int cropW = (_cropRect.width * imgW).toInt().clamp(1, imgW - cropX);
      final int cropH = (_cropRect.height * imgH).toInt().clamp(1, imgH - cropY);

      final bytes = await _imageFile!.readAsBytes();
      final img.Image? original = img.decodeImage(bytes);
      
      if (original != null) {
        final cropped = img.copyCrop(original, x: cropX, y: cropY, width: cropW, height: cropH);
        
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/crop_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(img.encodeJpg(cropped));

        final inputImage = InputImage.fromFilePath(tempFile.path);
        final result = await _textRecognizer.processImage(inputImage);
        
        if (mounted) {
          setState(() {
            _ocrResultText = result.text;
            // 自动展开面板
            if (_ocrResultText.isNotEmpty && _panelHeight < 200) {
              _panelHeight = 300;
            }
          });
        }
        tempFile.delete().ignore();
      }
    } catch (e) {
      debugPrint("OCR Error: $e");
    } finally {
      if (mounted) setState(() => _isRecognizing = false);
    }
  }
}

// --- 独立且高性能的 CropBox 组件 ---
class CropBox extends StatefulWidget {
  final Rect initialRect;
  final Size containerSize;
  final ValueChanged<Rect> onRectUpdate;     // 实时回调 (不 setState)
  final VoidCallback onInteractionEnd; // 结束回调 (触发 OCR)

  const CropBox({super.key, required this.initialRect, required this.containerSize, required this.onRectUpdate, required this.onInteractionEnd});

  @override
  State<CropBox> createState() => _CropBoxState();
}

class _CropBoxState extends State<CropBox> {
  late Rect _rect;
  final double touchSize = 30.0;
  
  @override
  void initState() {
    super.initState();
    _rect = widget.initialRect;
  }
  
  @override
  void didUpdateWidget(CropBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有当外部强制重置时才更新 (例如加载新图)，平时内部自己维护状态以避免父组件重绘干扰
    if (oldWidget.initialRect != widget.initialRect) {
      // 这里可以加逻辑判断，暂且信任内部状态优先
    }
  }

  @override
  Widget build(BuildContext context) {
    // 转换为本地像素坐标进行绘制
    final l = _rect.left * widget.containerSize.width;
    final t = _rect.top * widget.containerSize.height;
    final w = _rect.width * widget.containerSize.width;
    final h = _rect.height * widget.containerSize.height;

    return Stack(
      children: [
        // 1. 遮罩层 (支持点击瞬移)
        GestureDetector(
          onTapUp: (details) => _handleTap(details),
          child: CustomPaint(
            size: widget.containerSize,
            painter: MaskPainter(rect: Rect.fromLTWH(l, t, w, h)),
          ),
        ),
        
        // 2. 边框
        Positioned(
          left: l, top: t, width: w, height: h,
          child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5))),
        ),
        
        // 3. 中心拖动区域 (透明)
        Positioned(
          left: l + touchSize/2, top: t + touchSize/2, 
          width: w - touchSize > 0 ? w - touchSize : 0, 
          height: h - touchSize > 0 ? h - touchSize : 0,
          child: GestureDetector(
            onPanUpdate: _move,
            onPanEnd: (_) => widget.onInteractionEnd(),
            behavior: HitTestBehavior.translucent,
          ),
        ),
        
        // 4. 四角手柄
        _handle(l, t, _Corner.topLeft),
        _handle(l + w - touchSize, t, _Corner.topRight),
        _handle(l, t + h - touchSize, _Corner.bottomLeft),
        _handle(l + w - touchSize, t + h - touchSize, _Corner.bottomRight),
      ],
    );
  }
  
  Widget _handle(double l, double t, _Corner c) {
    return Positioned(
      left: l - 10, top: t - 10, width: touchSize + 20, height: touchSize + 20,
      child: GestureDetector(
        onPanUpdate: (d) => _resize(d, c),
        onPanEnd: (_) => widget.onInteractionEnd(),
        behavior: HitTestBehavior.translucent,
        child: Center(child: CustomPaint(size: Size(touchSize, touchSize), painter: HandlePainter(corner: c))),
      ),
    );
  }
  
  void _handleTap(TapUpDetails details) {
    // 点击瞬移，默认大小 30% x 15%
    const newW = 0.3; 
    const newH = 0.15;
    
    final dx = details.localPosition.dx / widget.containerSize.width;
    final dy = details.localPosition.dy / widget.containerSize.height;
    
    double left = dx - newW / 2;
    double top = dy - newH / 2;
    
    // 边界检查
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + newW > 1) left = 1 - newW;
    if (top + newH > 1) top = 1 - newH;
    
    final newRect = Rect.fromLTWH(left, top, newW, newH);
    
    setState(() => _rect = newRect); // 局部刷新
    widget.onRectUpdate(newRect);    // 通知外部数据变了
    widget.onInteractionEnd();       // 触发识别
  }
  
  void _move(DragUpdateDetails d) {
    final dx = d.delta.dx / widget.containerSize.width;
    final dy = d.delta.dy / widget.containerSize.height;
    final n = _rect.shift(Offset(dx, dy));
    
    if (n.left >= 0 && n.top >= 0 && n.right <= 1 && n.bottom <= 1) {
      setState(() => _rect = n); // 局部刷新
      widget.onRectUpdate(n);
    }
  }
  
  void _resize(DragUpdateDetails d, _Corner c) {
     final dx = d.delta.dx / widget.containerSize.width;
     final dy = d.delta.dy / widget.containerSize.height;
     double l = _rect.left, t = _rect.top, r = _rect.right, b = _rect.bottom;
     const min = 0.05;
     
     if (c == _Corner.topLeft) { l += dx; t += dy; if(l>r-min)l=r-min; if(t>b-min)t=b-min; }
     else if (c == _Corner.topRight) { r += dx; t += dy; if(r<l+min)r=l+min; if(t>b-min)t=b-min; }
     else if (c == _Corner.bottomLeft) { l += dx; b += dy; if(l>r-min)l=r-min; if(b<t+min)b=t+min; }
     else if (c == _Corner.bottomRight) { r += dx; b += dy; if(r<l+min)r=l+min; if(b<t+min)b=t+min; }
     
     final newRect = Rect.fromLTRB(l.clamp(0,1), t.clamp(0,1), r.clamp(0,1), b.clamp(0,1));
     setState(() => _rect = newRect); // 局部刷新
     widget.onRectUpdate(newRect);
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class MaskPainter extends CustomPainter {
  final Rect rect;
  MaskPainter({required this.rect});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height))..addRect(rect);
    p.fillType = PathFillType.evenOdd;
    canvas.drawPath(p, Paint()..color = Colors.black54);
  }
  @override
  bool shouldRepaint(MaskPainter old) => rect != old.rect;
}

class HandlePainter extends CustomPainter {
  final _Corner corner;
  HandlePainter({required this.corner});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white..strokeWidth = 3..style = PaintingStyle.stroke;
    final path = Path();
    const len = 15.0;
    if (corner == _Corner.topLeft) { path.moveTo(0, len); path.lineTo(0, 0); path.lineTo(len, 0); }
    else if (corner == _Corner.topRight) { path.moveTo(size.width - len, 0); path.lineTo(size.width, 0); path.lineTo(size.width, len); }
    else if (corner == _Corner.bottomLeft) { path.moveTo(0, size.height - len); path.lineTo(0, size.height); path.lineTo(len, size.height); }
    else if (corner == _Corner.bottomRight) { path.moveTo(size.width - len, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, size.height - len); }
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
