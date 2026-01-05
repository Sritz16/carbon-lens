import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class RealtimeScanner extends StatefulWidget {
  const RealtimeScanner({super.key});

  @override
  State<RealtimeScanner> createState() => _RealtimeScannerState();
}

class _RealtimeScannerState extends State<RealtimeScanner> {
  late CameraController _controller;
  late ObjectDetector _objectDetector;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<DetectedObject> _objects = [];

  // 🎨 COLORS FOR THE AR LIGHTS
  final Paint _goodPaint = Paint()
    ..color = Colors.greenAccent.withOpacity(0.5)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20); // Glowing Light Effect

  final Paint _badPaint = Paint()
    ..color = Colors.redAccent.withOpacity(0.5)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20); // Glowing Light Effect

  final Paint _borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDetector();
  }

  void _initializeDetector() {
    // We use the "Base" model which detects 5 categories:
    // Food, Plant (Good) vs HomeGood, FashionGood (Bad/Consumerism)
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Use the back camera
    final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // Medium is faster for ML
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _controller.initialize();
    
    // START STREAMING FRAMES
    _controller.startImageStream((image) {
      if (_isProcessing) return; // Drop frame if busy
      _isProcessing = true;
      _processImage(image);
    });

    setState(() => _isCameraInitialized = true);
  }

  Future<void> _processImage(CameraImage image) async {
    // 1. Convert CameraImage to ML Kit InputImage
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    // 2. Detect Objects
    final objects = await _objectDetector.processImage(inputImage);

    // 3. Update UI
    if (mounted) {
      setState(() {
        _objects = objects;
      });
    }
    _isProcessing = false;
  }

  // ------------------------------------------------------------------------
  // 🧹 UGLY BOILERPLATE TO CONVERT IMAGE FORMATS (REQUIRED FOR ML KIT)
  // ------------------------------------------------------------------------
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller.description;
    final sensorOrientation = camera.sensorOrientation;
    // For simplicity in hackathon, assuming Portrait Mode on Android
    final rotation = InputImageRotation.rotation90deg; 
    
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Combining bytes for Android (NV21)
    if (Platform.isAndroid && image.planes.length != 3) return null;
    
    // NOTE: This is a simplified converter for the hackathon. 
    // Ideally you use the official full converter snippet.
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Feed
          CameraPreview(_controller),

          // 2. The "AR Light" Overlay
          CustomPaint(
            painter: ArLightPainter(_objects, _goodPaint, _badPaint, _borderPaint),
          ),

          // 3. UI Overlay
          Positioned(
            bottom: 50,
            left: 20, 
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: const Text(
                "SCANNING ENVIRONMENT...\nGreen = Eco Friendly | Red = High Carbon",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Back Button
          Positioned(top: 50, left: 20, child: BackButton(color: Colors.white)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 🖌️ THE PAINTER: Draws lights over objects
// ---------------------------------------------------------
class ArLightPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Paint goodPaint;
  final Paint badPaint;
  final Paint borderPaint;

  ArLightPainter(this.objects, this.goodPaint, this.badPaint, this.borderPaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Scaling factors (Camera resolution vs Screen resolution)
    // For Hackathon speed, we assume standard portrait scaling.
    // In production, you calculate exact ratios.
    final double scaleX = size.width / 480.0; // standard ML Kit width
    final double scaleY = size.height / 640.0; // standard ML Kit height

    for (var object in objects) {
      // 1. Get the bounding box
      final rect = Rect.fromLTRB(
        object.boundingBox.left * scaleX,
        object.boundingBox.top * scaleY,
        object.boundingBox.right * scaleX,
        object.boundingBox.bottom * scaleY,
      );

      // 2. Decide Color based on Label
      // Labels: "Food", "Plant" -> Good. "Fashion good", "Home good" -> Bad.
      bool isEco = false;
      if (object.labels.isNotEmpty) {
        String label = object.labels.first.text.toLowerCase();
        if (label.contains("food") || label.contains("plant")) {
          isEco = true;
        }
      }

      // 3. Draw the "Light" (Glow)
      canvas.drawRect(rect, isEco ? goodPaint : badPaint);
      
      // 4. Draw Border
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}