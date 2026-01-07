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
  Size? _cameraImageSize; // To store exact camera resolution

  // 🎨 PAINTS
  final Paint _goodPaint = Paint()
    ..color = Colors.greenAccent.withOpacity(0.4)
    ..style = PaintingStyle.fill;

  final Paint _badPaint = Paint()
    ..color = Colors.redAccent.withOpacity(0.4)
    ..style = PaintingStyle.fill;

  final Paint _unknownPaint = Paint() // New: For objects with no clear label
    ..color = Colors.blueAccent.withOpacity(0.3)
    ..style = PaintingStyle.fill;

  final Paint _borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDetector();
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
    final cameras = await availableCameras();
    final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // keep medium for performance
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _controller.initialize();
    
    _controller.startImageStream((image) {
      if (_isProcessing) return;
      _isProcessing = true;
      _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());
      _processImage(image);
    });

    setState(() => _isCameraInitialized = true);
  }

  Future<void> _processImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    try {
      final objects = await _objectDetector.processImage(inputImage);
      
      // DEBUG PRINT: Check your terminal!
      if (objects.isNotEmpty) {
        print("🔎 Found ${objects.length} objects!");
        for(var obj in objects) {
             print("Label: ${obj.labels.map((l) => l.text).join(', ')}");
        }
      }

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

  // ------------------------------------------------------------------------
  // 🧹 CONVERTER UTILITY
  // ------------------------------------------------------------------------
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller),
          
          if (_cameraImageSize != null)
            CustomPaint(
              painter: ArLightPainter(
                _objects, 
                _cameraImageSize!, // Pass the real camera size
                _goodPaint, 
                _badPaint, 
                _unknownPaint,
                _borderPaint
              ),
            ),

          Positioned(
            bottom: 250, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text(
                "Detecting: ${_objects.length} Objects\nBlue = Unknown | Green = Eco | Red = High Carbon",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Positioned(top: 50, left: 20, child: BackButton(color: Colors.white)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 🖌️ FIXED SCALING PAINTER
// ---------------------------------------------------------
// ---------------------------------------------------------
// 🖌️ UPDATED PAINTER: SCANS EVERYTHING
// ---------------------------------------------------------
class ArLightPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size absoluteImageSize;
  final Paint goodPaint; // Green
  final Paint badPaint;  // Red
  final Paint unknownPaint; // Yellow (Analyzing)
  final Paint borderPaint;

  

  ArLightPainter(this.objects, this.absoluteImageSize, this.goodPaint, this.badPaint, this.unknownPaint, this.borderPaint);

  @override
  void paint(Canvas canvas, Size size) {
    // 📐 SCALING MATH (Fixes the "Invisible Box" issue)
    final double scaleX = size.width / absoluteImageSize.height; 
    final double scaleY = size.height / absoluteImageSize.width;

    for (var object in objects) {
      // 1. Draw the Box
      final rect = Rect.fromLTRB(
        object.boundingBox.left * scaleX,
        object.boundingBox.top * scaleY,
        object.boundingBox.right * scaleX,
        object.boundingBox.bottom * scaleY,
      );

      // 2. THE NEW "CATCH-ALL" LOGIC
      // Default to RED (assume manufactured/carbon heavy unless proven otherwise)
      Paint chosenPaint = badPaint; 
      
      if (object.labels.isNotEmpty) {
        String label = object.labels.first.text.toLowerCase();
        
        // 🌿 GREEN: Nature, Food, Plants
        if (label.contains("food") || 
            label.contains("plant") || 
            label.contains("fruit") || 
            label.contains("vegetable")) {
          chosenPaint = goodPaint;
        } 
        // 🏭 RED: Home Goods, Fashion, Electronics (The "Everything Else")
        else if (label.contains("home") || 
                 label.contains("fashion") || 
                 label.contains("good") || 
                 label.contains("electronic")) {
          chosenPaint = badPaint;
        }
        // 🟡 YELLOW: Places / Uncertain things
        else if (label.contains("place")) {
          chosenPaint = unknownPaint; 
        }
      } else {
        // If the AI detects an object but has NO clue what it is, 
        // treat it as "High Carbon" (Safe bet for manufactured objects)
        chosenPaint = badPaint;
      }

      // 3. Draw the Glowing Light
      canvas.drawRect(rect, chosenPaint);
      
      // 4. Draw the White Border
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}