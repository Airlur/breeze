import 'dart:async';
import 'dart:io';
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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
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
                if (_isImageLoaded)
                  Positioned.fill(
                    top: 60,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _calculateImageRect(constraints.biggest);
                        return Stack(
                          children: [
                            Positioned.fromRect(
                              rect: _imageDisplayRect,
                              child: Image.file(_imageFile!, fit: BoxFit.fill),
                            ),
                            Positioned.fromRect(
                              rect: _imageDisplayRect,
                              child: CropBox(
                                initialRect: _cropRect,
                                containerSize: _imageDisplayRect.size,
                                onRectUpdate: (val) => _cropRect = val,
                                onInteractionEnd: _triggerAutoRecognize,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                if (_ocrResultText.isEmpty && !_isRecognizing)
                   const Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: Center(child: Text("拖动选区以识别文字", style: TextStyle(color: Colors.white70, shadows: [Shadow(blurRadius: 2, color: Colors.black)]))),
                  ),
              ],
            ),
          ),
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
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
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
  
  void _calculateImageRect(Size containerSize) {
    if (_loadedImage == null) return;
    final double imgAspectRatio = _loadedImage!.width / _loadedImage!.height;
    final double containerAspectRatio = containerSize.width / containerSize.height;
    double displayW, displayH;
    if (containerAspectRatio > imgAspectRatio) {
      displayH = containerSize.height;
      displayW = displayH * imgAspectRatio;
    } else {
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

class CropBox extends StatefulWidget {
  final Rect initialRect;
  final Size containerSize;
  final ValueChanged<Rect> onRectUpdate;
  final VoidCallback onInteractionEnd;

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
    if (oldWidget.initialRect != widget.initialRect) {
       // logic to update internal state if external props change significantly
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _rect.left * widget.containerSize.width;
    final t = _rect.top * widget.containerSize.height;
    final w = _rect.width * widget.containerSize.width;
    final h = _rect.height * widget.containerSize.height;

    return Stack(
      children: [
        GestureDetector(
          onTapUp: (details) => _handleTap(details),
          child: CustomPaint(
            size: widget.containerSize,
            painter: MaskPainter(rect: Rect.fromLTWH(l, t, w, h)),
          ),
        ),
        Positioned(
          left: l, top: t, width: w, height: h,
          child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5))),
        ),
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
        _handle(l, t, Corner.topLeft),
        _handle(l + w - touchSize, t, Corner.topRight),
        _handle(l, t + h - touchSize, Corner.bottomLeft),
        _handle(l + w - touchSize, t + h - touchSize, Corner.bottomRight),
      ],
    );
  }
  
  Widget _handle(double l, double t, Corner c) {
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
    const newW = 0.3; 
    const newH = 0.15;
    final dx = details.localPosition.dx / widget.containerSize.width;
    final dy = details.localPosition.dy / widget.containerSize.height;
    double left = dx - newW / 2;
    double top = dy - newH / 2;
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + newW > 1) left = 1 - newW;
    if (top + newH > 1) top = 1 - newH;
    final newRect = Rect.fromLTWH(left, top, newW, newH);
    setState(() => _rect = newRect);
    widget.onRectUpdate(newRect);
    widget.onInteractionEnd();
  }
  
  void _move(DragUpdateDetails d) {
    final dx = d.delta.dx / widget.containerSize.width;
    final dy = d.delta.dy / widget.containerSize.height;
    final n = _rect.shift(Offset(dx, dy));
    if (n.left >= 0 && n.top >= 0 && n.right <= 1 && n.bottom <= 1) {
      setState(() => _rect = n);
      widget.onRectUpdate(n);
    }
  }
  
  void _resize(DragUpdateDetails d, Corner c) {
     final dx = d.delta.dx / widget.containerSize.width;
     final dy = d.delta.dy / widget.containerSize.height;
     double l = _rect.left, t = _rect.top, r = _rect.right, b = _rect.bottom;
     const min = 0.05;
     if (c == Corner.topLeft) { l += dx; t += dy; if(l>r-min)l=r-min; if(t>b-min)t=b-min; }
     else if (c == Corner.topRight) { r += dx; t += dy; if(r<l+min)r=l+min; if(t>b-min)t=b-min; }
     else if (c == Corner.bottomLeft) { l += dx; b += dy; if(l>r-min)l=r-min; if(b<t+min)b=t+min; }
     else if (c == Corner.bottomRight) { r += dx; b += dy; if(r<l+min)r=l+min; if(b<t+min)b=t+min; }
     final newRect = Rect.fromLTRB(l.clamp(0,1), t.clamp(0,1), r.clamp(0,1), b.clamp(0,1));
     setState(() => _rect = newRect);
     widget.onRectUpdate(newRect);
  }
}

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

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
  final Corner corner;
  HandlePainter({required this.corner});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white..strokeWidth = 3..style = PaintingStyle.stroke;
    final path = Path();
    const len = 15.0;
    if (corner == Corner.topLeft) { path.moveTo(0, len); path.lineTo(0, 0); path.lineTo(len, 0); }
    else if (corner == Corner.topRight) { path.moveTo(size.width - len, 0); path.lineTo(size.width, 0); path.lineTo(size.width, len); }
    else if (corner == Corner.bottomLeft) { path.moveTo(0, size.height - len); path.lineTo(0, size.height); path.lineTo(len, size.height); }
    else if (corner == Corner.bottomRight) { path.moveTo(size.width - len, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, size.height - len); }
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}