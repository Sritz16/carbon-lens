import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Database Import
import 'package:google_generative_ai/google_generative_ai.dart';
import 'firebase_options.dart';

// ⚠️ PASTE YOUR WORKING "NUCLEAR" KEY HERE
const String apiKey = "AIzaSyAWsUZfQtE6gzLHulUe7HCDooWI81Sccqg"; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String _resultText = "Scan a meal to see its shadow.";
  bool _isLoading = false;
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-flash-latest', // ✅ The fast, high-quota model
      apiKey: apiKey,
    );
  }

  // 👇 1. The Database Function
  Future<void> _saveToDatabase(String fullText) async {
    print("💾 ATTEMPTING TO SAVE DATA..."); // Debug log

    try {
      // Create a neat data object
      final data = {
        'scan_result': fullText,
        'timestamp': FieldValue.serverTimestamp(),
        'device_os': Platform.operatingSystem,
      };

      // Push to Firebase
      await FirebaseFirestore.instance.collection('scans').add(data);

      print("✅ SAVE SUCCESSFUL!"); // Debug log
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Saved to Cloud Database!"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print("❌ SAVE FAILED: $e"); // Debug log
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Database Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzeImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;

      setState(() {
        _selectedImage = File(photo.path);
        _isLoading = true;
        _resultText = "Analyzing...";
      });

      final prompt = TextPart("Identify this food. Estimate carbon footprint. Format: 'Item: [Name] \n Impact: [X] kg CO2e \n Swap: [Alternative]'");
      final imageBytes = await _selectedImage!.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final finalText = response.text ?? "No result found.";

      setState(() {
        _resultText = finalText;
        _isLoading = false;
      });

      // 👇 2. Trigger the Save
      await _saveToDatabase(finalText);

    } catch (e) {
      print("❌ APP CRASH: $e");
      setState(() {
        _resultText = "Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carbon Scanner"), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: _selectedImage == null
                  ? const Icon(Icons.camera_alt, size: 100, color: Colors.grey)
                  : Image.file(_selectedImage!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            _isLoading 
               ? const CircularProgressIndicator()
               : Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Text(_resultText, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                 ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeImage,
              child: const Text("SCAN & SAVE"),
            ),
          ],
        ),
      ),
    );
  }
}