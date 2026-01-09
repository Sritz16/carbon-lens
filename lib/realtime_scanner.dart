import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter/foundation.dart';

class RealtimeScanner extends StatefulWidget {
  const RealtimeScanner({super.key});

  @override
  State<RealtimeScanner> createState() => _RealtimeScannerState();
}

class _RealtimeScannerState extends State<RealtimeScanner> with TickerProviderStateMixin {
  late CameraController _controller;
  late ObjectDetector _objectDetector;
  
  late AnimationController _rotationController; 
  late AnimationController _pulseController;    

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<DetectedObject> _objects = [];
  Size? _cameraImageSize; 

  // 🎨 PALETTE
  final Color _cyan = const Color(0xFF00FFC2); // Eco
  final Color _red = const Color(0xFFFF2E2E);  // Carbon
  final Color _amber = const Color(0xFFFFC107); // Unknown

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDetector();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  void _initializeDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        print("No cameras found");
        return;
      }

      // ✅ FIX 1: Smart Camera Selection
      // Tries to find a Back Camera (Phone). If none (Laptop), picks the first available one.
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first, 
      );

      // ✅ FIX 2: Initialize with LOW resolution
      // 'medium' or 'low' prevents freezing on laptop webcams.
      _controller = CameraController(
        camera,
        ResolutionPreset.medium, 
        enableAudio: false,
        // ✅ FIX 3: Web-Safe Image Format
        // 'kIsWeb' prevents the app from crashing by checking for "Android" on a browser.
        imageFormatGroup: kIsWeb 
            ? ImageFormatGroup.unknown 
            : (defaultTargetPlatform == TargetPlatform.android 
                ? ImageFormatGroup.nv21 
                : ImageFormatGroup.bgra8888),
      );

      await _controller!.initialize();
      
      _controller!.startImageStream((image) {
        if (_isProcessing) return; // Prevents freezing by skipping frames if busy
        _isProcessing = true;
        
        // Safety check for image sizes
        _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());
        
        _processImage(image); // Your AI logic
      });

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
      
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  Future<void> _processImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    try {
      final objects = await _objectDetector.processImage(inputImage);
      if (mounted) {
        setState(() {
          _objects = objects;
        });
      }
    } catch (e) {
      print("Error detecting objects: $e");
    }
    _isProcessing = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller.description;
    final sensorOrientation = camera.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation90deg;
    
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    
    return InputImage.fromBytes(
      bytes: Uint8List.fromList(
        image.planes.fold<List<int>>([], (previousValue, plane) => previousValue..addAll(plane.bytes)),
      ),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _objectDetector.close();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFF00FFC2))));

    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. CAMERA FEED
          CameraPreview(_controller),
          
          // 2. TECH GRID
          CustomPaint(painter: TechGridPainter(color: _cyan.withOpacity(0.1))),

          // 3. CENTER ROTATING RING
          Center(
            child: RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _cyan.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: CustomPaint(painter: CenterReticlePainter(color: _cyan)),
              ),
            ),
          ),

          // 4. INTELLIGENT BOUNDING BOXES (FULL BOXES)
          if (_cameraImageSize != null)
            CustomPaint(
              painter: JarvisBoxPainter(
                _objects, 
                _cameraImageSize!, 
                _cyan, 
                _red, 
                _amber 
              ),
            ),

          // 5. PERIMETER DECORATIONS
          Positioned(top: 50, left: 20, child: TechCorner(color: _cyan)),
          Positioned(top: 50, right: 20, child: Transform.flip(flipX: true, child: TechCorner(color: _cyan))),
          Positioned(bottom: 50, left: 20, child: Transform.flip(flipY: true, child: TechCorner(color: _cyan))),
          Positioned(bottom: 50, right: 20, child: Transform.flip(flipX: true, flipY: true, child: TechCorner(color: _cyan))),

          // 6. TOP HUD
          Positioned(
            top: 60, 
            left: 30,
            right: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6), 
                    border: Border.all(color: _cyan.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.adjust, color: _cyan, size: 18),
                          const SizedBox(width: 8),
                          CyberText(
                            text: _objects.isNotEmpty 
                                ? "TARGET LOCK: ${_objects.length} OBJECTS" 
                                : "SCANNING SECTOR...",
                            style: TextStyle(
                              fontFamily: 'Courier', 
                              color: _cyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.5
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 7. BOTTOM STATUS BAR
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                 _StatusBlock(label: "BIO-SAFE", color: _cyan, isActive: _objects.any((o) => _classify(o) == 'eco')),
                 _StatusBlock(label: "UNKNOWN", color: _amber, isActive: _objects.any((o) => _classify(o) == 'unknown')),
                 _StatusBlock(label: "CARBON HAZARD", color: _red, isActive: _objects.any((o) => _classify(o) == 'carbon')),
              ],
            ),
          ),
          
          Positioned(top: 55, left: 10, child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )),
        // ✅ PASTE THIS AT THE BOTTOM OF YOUR 'Stack' CHILDREN LIST
          Positioned(
            top: 40, // Moves it down from the top status bar
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // <--- Go back to Dashboard
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5), // Semi-transparent dark background
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyanAccent, width: 2), // Cyberpunk border
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new, 
                  color: Colors.white, 
                  size: 24
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _classify(DetectedObject object) {
    if (object.labels.isEmpty) return 'unknown';
    String label = object.labels.first.text.toLowerCase();

    if (label.contains('plant') || 
        label.contains('food') || 
        label.contains('vegetable') || 
        label.contains('fruit') || 
        label.contains('flower') || 
        label.contains('person') || 
        label.contains('wood') ||
        label.contains('paper')) {
      return 'eco';
    } 
    
    if (label.contains('electronic') || 
        label.contains('computer') || 
        label.contains('phone') || 
        label.contains('car') || 
        label.contains('vehicle') || 
        label.contains('plastic') || 
        label.contains('bottle') || 
        label.contains('bag') || 
        label.contains('shoe') ||
        label.contains('clothing') ||
        label.contains('fashion') || 
        label.contains('home good') || 
        label.contains('ware') ||
        label.contains('tool') ||
        label.contains('appliance')) {
      return 'carbon';
    }

    return 'unknown';
  }
}

// ---------------------------------------------------------
// 📟 HELPERS
// ---------------------------------------------------------

class _StatusBlock extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;

  const _StatusBlock({required this.label, required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.8), width: 1.5),
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)] : []
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color, 
            fontFamily: 'Courier', 
            fontWeight: FontWeight.bold,
            fontSize: 11
          ),
        ),
      ),
    );
  }
}

class CenterReticlePainter extends CustomPainter {
  final Color color;
  CenterReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, pi / 2, false, paint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi / 2, false, paint);

    final tickPaint = Paint()..color = color.withOpacity(0.3)..strokeWidth = 2;
    for (int i = 0; i < 360; i += 30) {
      double angle = i * pi / 180;
      double x1 = center.dx + (radius - 15) * cos(angle);
      double y1 = center.dy + (radius - 15) * sin(angle);
      double x2 = center.dx + (radius - 25) * cos(angle);
      double y2 = center.dy + (radius - 25) * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TechGridPainter extends CustomPainter {
  final Color color;
  TechGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    double step = 50.0; 
    
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JarvisBoxPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size absoluteImageSize;
  final Color ecoColor;
  final Color warnColor;
  final Color unknownColor;

  JarvisBoxPainter(this.objects, this.absoluteImageSize, this.ecoColor, this.warnColor, this.unknownColor);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.height;
    final double scaleY = size.height / absoluteImageSize.width;

    for (var object in objects) {
      final rect = Rect.fromLTRB(
        object.boundingBox.left * scaleX,
        object.boundingBox.top * scaleY,
        object.boundingBox.right * scaleX,
        object.boundingBox.bottom * scaleY,
      );

      Color paintColor = unknownColor;
      if (object.labels.isNotEmpty) {
        String label = object.labels.first.text.toLowerCase();
        
        if (label.contains('plant') || label.contains('food') || label.contains('fruit') || label.contains('vegetable') || label.contains('flower') || label.contains('person') || label.contains('wood') || label.contains('paper')) {
          paintColor = ecoColor;
        } 
        else if (label.contains('electronic') || label.contains('computer') || label.contains('phone') || label.contains('car') || label.contains('vehicle') || label.contains('plastic') || label.contains('bottle') || label.contains('bag') || label.contains('shoe') || label.contains('clothing') || label.contains('fashion') || label.contains('home good') || label.contains('ware') || label.contains('tool')) {
          paintColor = warnColor;
        }
      }

      // 🎨 FULL BOX DRAWING
      final fillPaint = Paint()
        ..color = paintColor.withOpacity(0.25)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = paintColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);

      if (object.labels.isNotEmpty) {
        String labelText = object.labels.first.text.toUpperCase();
        
        final textSpan = TextSpan(
          text: labelText,
          style: TextStyle(
            color: paintColor, 
            fontSize: 12,
            fontWeight: FontWeight.bold, 
            fontFamily: 'Courier',
            backgroundColor: Colors.black.withOpacity(0.7)
          ),
        );
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, Offset(rect.left, rect.top - 20)); 
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TechCorner extends StatelessWidget {
  final Color color;
  const TechCorner({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40, height: 40,
      child: CustomPaint(
        painter: _CornerPainter(color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------
// 🛠️ CRASH FIXED CYBER TEXT
// ---------------------------------------------------------
class CyberText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const CyberText({super.key, required this.text, required this.style});
  @override
  State<CyberText> createState() => _CyberTextState();
}

class _CyberTextState extends State<CyberText> {
  String _displayed = "";
  final Random _random = Random();
  final String _chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*";

  @override
  void initState() {
    super.initState();
    _animate();
  }
  
  @override
  void didUpdateWidget(covariant CyberText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _animate();
  }

  // 🛠️ FIX: Added (!mounted) checks to prevent crash
  void _animate() async {
    String target = widget.text;
    for (int i = 0; i <= target.length; i++) {
      if (!mounted) return;
      
      if (i < target.length) {
        String randomChar = _chars[_random.nextInt(_chars.length)];
        setState(() => _displayed = target.substring(0, i) + randomChar);
        await Future.delayed(const Duration(milliseconds: 10));
        if (!mounted) return;
      }
      
      setState(() => _displayed = target.substring(0, i));
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Text(_displayed, style: widget.style);
  }
}