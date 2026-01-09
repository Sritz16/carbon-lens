import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter/foundation.dart';

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
  void _processImage(CameraImage image) async {
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
      print("Detection Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        print("No cameras found");
        return;
      }

      // ✅ FIX 1: Smart Camera Selection
      // If no Back Camera is found (Laptop), it uses the first available one (Webcam).
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first, 
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // Medium is safest for Web
        enableAudio: false,
        // ✅ FIX 2: Web Safety
        // We only use the specific format on Android. On Web, we let Flutter decide.
        imageFormatGroup: kIsWeb 
            ? ImageFormatGroup.unknown // Web handles this automatically
            : (defaultTargetPlatform == TargetPlatform.android 
                ? ImageFormatGroup.nv21 
                : ImageFormatGroup.bgra8888),
      );

      await _controller.initialize();
      
      _controller.startImageStream((image) {
        if (_isProcessing) return;
        _isProcessing = true;
        _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());
        _processImage(image);
      });

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
      
    } catch (e) {
      print("Camera Error: $e");
    }
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
    // 📐 SCALING MATH
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

      // 2. 🧠 SMARTER LOGIC: Default to Blue (Neutral), not Red
      Paint chosenPaint = unknownPaint; 
      
      if (object.labels.isNotEmpty) {
        String label = object.labels.first.text.toLowerCase();
        
        // 🌿 GREEN: Nature, Food, Paper, People
        if (label.contains("food") || 
            label.contains("plant") || 
            label.contains("fruit") || 
            label.contains("vegetable") ||
            label.contains("flower") ||
            label.contains("tree") ||
            label.contains("wood") ||    // Wood is usually sustainable
            label.contains("paper") ||   
            label.contains("person")) {  // Humans are not "High Carbon"!
          chosenPaint = goodPaint;
        } 
        
        // 🏭 RED: Electronics, Plastics, Vehicles, Industrial, & Accessories
        else if (label.contains("electronic") || 
                 label.contains("computer") || 
                 label.contains("phone") || 
                 label.contains("mobile") ||
                 label.contains("cell") ||
                 label.contains("screen") ||
                 label.contains("monitor") ||
                 label.contains("laptop") ||
                 label.contains("tablet") ||
                 // 👇 NEW: Audio & Accessories
                 label.contains("headphone") ||
                 label.contains("headset") ||
                 label.contains("earphone") ||
                 label.contains("earbud") ||
                 label.contains("audio") ||
                 label.contains("speaker") ||
                 label.contains("camera") ||
                 label.contains("remote") ||
                 label.contains("control") ||
                 label.contains("game") ||
                 label.contains("cable") ||
                 label.contains("wire") ||
                 label.contains("glass") ||  // Screens often detect as glass
                 label.contains("watch") ||
                 // 👇 NEW: Generic Manufactured Goods
                 label.contains("tool") ||
                 label.contains("hardware") ||
                 label.contains("equipment") ||
                 label.contains("accessory") ||
                 label.contains("bag") ||    // Leather/Synthetic
                 label.contains("shoe") ||   // Fast fashion
                 label.contains("clothing") ||
                 label.contains("car") || 
                 label.contains("vehicle") || 
                 label.contains("plastic") || 
                 label.contains("bottle") || 
                 label.contains("can") ||
                 label.contains("metal") ||  
                 label.contains("appliance")) {
          chosenPaint = badPaint;
        }
        
        // 🔵 BLUE: Everything else (Furniture, Rooms, Walls, Clothes, Bags)
        // This effectively "ignores" the background noise.
        // 🔵 NEUTRAL / BLUE
        else {
           // HACKATHON TRICK:
           // If the label is just "Object" or "Home good", treat it as Red (safe bet).
           if (label == "object" || label.contains("good") || label.contains("item")) {
             chosenPaint = badPaint; // Force Red for vague items
           } else {
             chosenPaint = unknownPaint; // Truly unknown stuff stays Blue
           }
        }
      }

      // 3. Draw the visuals
      canvas.drawRect(rect, chosenPaint);
      canvas.drawRect(rect, borderPaint);
      
      // 4. (Optional) DRAW TEXT LABEL
      // This helps you verify *what* the AI actually sees.
      if (object.labels.isNotEmpty) {
        final textSpan = TextSpan(
          text: object.labels.first.text.toUpperCase(),
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            backgroundColor: Colors.black45
          ),
        );
        final textPainter = TextPainter(
          text: textSpan, 
          textDirection: TextDirection.ltr
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}