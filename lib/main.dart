import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ⚠️ PASTE YOUR WORKING KEY HERE ⚠️
const String apiKey = "AIzaSyDu0fv0DEOHisIfgAM9sxJ5Qx0AJ_a_RCw"; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print("Firebase Setup Error: $e");
  }
  runApp(const MyApp());
}

// ---------------------------------------------------------
// 1. APP ROOT & THEME MANAGER
// ---------------------------------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void toggleTheme(BuildContext context) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.toggleTheme();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Carbon Shadow',
      // ✨ LIGHT THEME (Fixed: Removed CardTheme to prevent errors)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      // 🌑 DARK THEME (Fixed)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
            titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      themeMode: _themeMode,
      home: const AuthGate(),
    );
  }
}

// ---------------------------------------------------------
// 2. AUTH GATE
// ---------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ---------------------------------------------------------
// 3. LOGIN SCREEN
// ---------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Auth Error"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                _isLogin ? "Welcome Back" : "Join the Movement",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Track your invisible carbon impact.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLogin ? "LOGIN" : "CREATE ACCOUNT"),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? "New here? Create Account" : "Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. MAIN NAV SCREEN
// ---------------------------------------------------------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const ScannerScreen(),
    const TravelScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.green),
            SizedBox(width: 8),
            Text("Carbon Shadow"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => MyApp.toggleTheme(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Scanner'),
          NavigationDestination(icon: Icon(Icons.commute_outlined), selectedIcon: Icon(Icons.commute), label: 'Travel'),
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 5. SCANNER SCREEN
// ---------------------------------------------------------
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _scanData; 
  String _statusMessage = "Ready to Scan"; 
  bool _isLoading = false;

  Gradient _getShadowGradient(int score) {
    if (score < 30) {
      return LinearGradient(
        begin: Alignment.bottomCenter, end: Alignment.topCenter,
        colors: [Colors.green.withOpacity(0.6), Colors.transparent],
      );
    } else if (score < 70) {
      return LinearGradient(
        begin: Alignment.bottomCenter, end: Alignment.topCenter,
        colors: [Colors.orange.withOpacity(0.5), Colors.transparent],
      );
    } else {
      return LinearGradient(
        begin: Alignment.bottomCenter, end: Alignment.topCenter,
        colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.2), Colors.transparent],
      );
    }
  }

  Future<void> _saveToDatabase(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('scans').add({
        ...data,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { print("DB Error: $e"); }
  }

  Future<void> _analyzeImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _selectedImage = File(photo.path);
      _isLoading = true;
      _statusMessage = "🧠 AI is analyzing...";
      _scanData = null; 
    });

    try {
      final bytes = await File(photo.path).readAsBytes();
      String base64Image = base64Encode(bytes);
      final cleanKey = apiKey.trim();
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$cleanKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [
              {
                "text": "Analyze this item for Carbon Footprint. Return raw JSON (no markdown): {'item_name': 'Name', 'carbon_score': 85, 'shadow_type': 'High Impact', 'nudge_text': 'Suggestion', 'tree_analogy': 'Trees explanation'}"
              },
              {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}
            ]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String finalText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        finalText = finalText.replaceAll("```json", "").replaceAll("```", "").trim();
        final Map<String, dynamic> parsedData = jsonDecode(finalText);

        setState(() { _scanData = parsedData; _isLoading = false; });
        await _saveToDatabase(parsedData);
      } else {
        setState(() { _statusMessage = "Server Error: ${response.statusCode}"; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _statusMessage = "Failed. Try again."; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(
              height: 400,
              width: double.infinity,
              child: _selectedImage == null
                  ? Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add_a_photo, size: 60, color: Colors.grey), SizedBox(height: 10), Text("Tap Scan to begin")]),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_selectedImage!, fit: BoxFit.cover),
                        if (_scanData != null) Container(decoration: BoxDecoration(gradient: _getShadowGradient(_scanData!['carbon_score']))),
                        if (_scanData != null) Positioned(bottom: 20, left: 20, child: Chip(avatar: const Icon(Icons.blur_on, size: 16), label: Text("Visualizing ${_scanData!['shadow_type']}"))),
                      ],
                    ),
            ),
            
            if (_isLoading) Padding(padding: const EdgeInsets.all(40), child: Column(children: [const CircularProgressIndicator(), const SizedBox(height:10), Text(_statusMessage)])),
            
            if (_scanData != null && !_isLoading) Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_scanData!['item_name'] ?? "Item", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${_scanData!['carbon_score']}", style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                        const Padding(padding: EdgeInsets.only(bottom: 12, left: 8), child: Text("/ 100 Impact", style: TextStyle(fontSize: 18, color: Colors.grey))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.forest, color: Colors.green, size: 32),
                        title: const Text("Tree Analogy", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_scanData!['tree_analogy'] ?? ""),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      color: Colors.blue.withOpacity(0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.lightbulb, color: Colors.blue, size: 32),
                        title: const Text("Suggestion", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_scanData!['nudge_text'] ?? "No suggestion."),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _analyzeImage,
        icon: const Icon(Icons.center_focus_strong),
        label: Text(_isLoading ? "Analyzing..." : "SCAN ITEM"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ---------------------------------------------------------
// 6. TRAVEL SCREEN
// ---------------------------------------------------------
class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});
  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  final _distanceController = TextEditingController();
  String _selectedMode = "Car";
  double _calculatedEmission = 0.0;
  bool _isSaving = false;

  final Map<String, double> _emissionFactors = {
    "Car": 0.192, "Bus": 0.105, "Motorbike": 0.103, "Train": 0.041, "Bicycle": 0.0, "Walk": 0.0,
  };

  void _calculateImpact() {
    double dist = double.tryParse(_distanceController.text) ?? 0.0;
    setState(() { _calculatedEmission = dist * (_emissionFactors[_selectedMode] ?? 0.0); });
  }

  Future<void> _logTravel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_distanceController.text.isEmpty || user == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('scans').add({
        'item_name': "$_selectedMode Trip",
        'carbon_score': (_calculatedEmission * 100).toInt().clamp(0, 100),
        'shadow_type': _calculatedEmission > 0.5 ? "High Travel Impact" : "Low Travel Impact",
        'nudge_text': _selectedMode == "Car" ? "Try public transport to save CO2." : "Great eco-choice!",
        'tree_analogy': "Emitted ${_calculatedEmission.toStringAsFixed(2)} kg of CO2.",
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Trip Logged!"), backgroundColor: Colors.green));
      _distanceController.clear();
      setState(() { _calculatedEmission = 0.0; _isSaving = false; });
    } catch (e) { setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Travel Log", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            DropdownButtonFormField<String>(
              value: _selectedMode,
              decoration: InputDecoration(
                labelText: "Mode of Transport",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.directions_car),
              ),
              items: _emissionFactors.keys.map((String mode) {
                return DropdownMenuItem<String>(value: mode, child: Text(mode));
              }).toList(),
              onChanged: (val) { setState(() { _selectedMode = val!; _calculateImpact(); }); },
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _distanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Distance (km)",
                suffixText: "km",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.map),
              ),
              onChanged: (val) => _calculateImpact(),
            ),
            const SizedBox(height: 40),
            
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text("Impact Estimate", style: Theme.of(context).textTheme.labelLarge),
                    Text("${_calculatedEmission.toStringAsFixed(2)} kg", style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Text("CO₂ Emissions"),
                  ],
                ),
              ),
            ),
            const Spacer(),
            
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _logTravel,
                icon: const Icon(Icons.save_alt),
                label: Text(_isSaving ? "Saving..." : "LOG TRIP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 7. HISTORY SCREEN
// ---------------------------------------------------------
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please Login"));

    return Scaffold(
      // REPLACE THE ENTIRE body: StreamBuilder(...) BLOCK IN HistoryScreen WITH THIS:

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scans')
            .where('userId', isEqualTo: user.uid) // ✅ Filter by user ONLY
            // .orderBy('timestamp', descending: true) ❌ REMOVED to fix loading stuck
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}")); 
          }

          if (!snapshot.hasData) {
             return const Center(child: CircularProgressIndicator());
          }

          // ✅ FIX: Sort the data here on the phone instead of the database
          final docs = snapshot.data!.docs;
          docs.sort((a, b) {
             // Sort by timestamp manually (Newest first)
             Timestamp? timeA = (a.data() as Map)['timestamp'];
             Timestamp? timeB = (b.data() as Map)['timestamp'];
             if (timeA == null || timeB == null) return 0;
             return timeB.compareTo(timeA); 
          });

          // Calculate Score
          int totalPoints = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalPoints += (100 - (data['carbon_score'] as int? ?? 50)).clamp(0, 100);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              // GAMIFICATION CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00b09b), Color(0xFF96c93d)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("TOTAL POINTS", style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Earth Hero", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text("$totalPoints", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("Recent Activity", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (docs.isEmpty) 
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No scans yet. Start scanning!"))),

              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final int score = data['carbon_score'] ?? 0;
                Color scoreColor = score < 30 ? Colors.green : (score < 70 ? Colors.orange : Colors.red);
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: scoreColor.withOpacity(0.2),
                      child: Text("$score", style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(data['item_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['tree_analogy'] ?? "Processed", maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}