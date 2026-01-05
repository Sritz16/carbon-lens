import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'realtime_scanner.dart';


// ⚠️ YOUR API KEY
const String apiKey = "AIzaSyDu0fv0DEOHisIfgAM9sxJ5Qx0AJ_a_RCw"; 

// 1. ADD THIS GLOBAL NOTIFIER
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    print("Firebase Setup Error: $e");
  }
  runApp(const CarbonTrackerApp());
}

class CarbonTrackerApp extends StatelessWidget {
  const CarbonTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. WRAP MATERIALAPP IN LISTENER
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Carbon Shadow',
          themeMode: mode, // Uses the notifier value
          
          // LIGHT THEME (Ensuring it looks BRIGHT)
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F7F6), // Soft White
            primaryColor: const Color(0xFF006C50),
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF006C50),
              secondary: const Color(0xFF00D1A3),
              surface: Colors.white,
              onSurface: const Color(0xFF1A1C19),
            ),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 2, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent, 
              elevation: 0, 
              centerTitle: true,
              titleTextStyle: TextStyle(color: Color(0xFF006C50), fontWeight: FontWeight.w900, fontSize: 22)
            ),
          ),

          // DARK THEME
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: const Color(0xFF00E676),
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF00E676),
              secondary: const Color(0xFF00A878),
              surface: const Color(0xFF1E1E1E),
              onSurface: const Color(0xFFE0E0E0),
            ),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF1E1E1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent, 
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.w900, fontSize: 22)
            ),
          ),
          home: const AuthGate(),
        );
      },
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
        if (snapshot.hasData) return const MainScreen();
        return const LoginScreen();
      },
    );
  }
}

// ---------------------------------------------------------
// 3. LOGIN & SIGN UP SCREEN (Fixed with Name Field)
// ---------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController(); // NEW: Name Controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    if (!_isLogin && _nameController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your name for the leaderboard!")));
       return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(), 
          password: _passwordController.text.trim()
        );
      } else {
        // 1. Create User
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(), 
          password: _passwordController.text.trim()
        );
        
        // 2. Create Database Entry for Leaderboard
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': _emailController.text.trim(),
          'displayName': _nameController.text.trim(), // Saving Name
          'totalPoints': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withOpacity(0.8), const Color(0xFF121212)], 
            begin: Alignment.topLeft, end: Alignment.bottomRight
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, size: 60, color: primaryColor),
                    const SizedBox(height: 20),
                    Text(_isLogin ? "Welcome Back" : "Join the Movement", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    // Show Name field ONLY if Signing Up
                    if (!_isLogin)
                      TextField(
                        controller: _nameController, 
                        decoration: InputDecoration(labelText: "Display Name", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
                      ),
                    if (!_isLogin) const SizedBox(height: 10),

                    TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email", prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 10),
                    TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: "Password", prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),
                    
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit, 
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? "LOGIN" : "SIGN UP")
                    )),
                    
                    TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "New here? Create Account" : "Have an account? Login")),
                  ],
                ),
              ),
            ),
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
  const DashboardScreen(),
  const TravelScreen(),
  const ScannerScreen(), 
  const LeaderboardScreen(),
  const ProfileScreen(),
  const ArScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        height: 65,
        backgroundColor: Theme.of(context).cardTheme.color,
        indicatorColor: Theme.of(context).primaryColor.withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: "Dash"),
          NavigationDestination(icon: Icon(Icons.directions_bus_outlined), selectedIcon: Icon(Icons.directions_bus), label: "Travel"),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), selectedIcon: Icon(Icons.qr_code), label: "Scan"),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: "Rank"),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 5. DASHBOARD SCREEN (Fixed Timestamps & Levels)
// ---------------------------------------------------------
// ---------------------------------------------------------
// REPLACEMENT: DASHBOARD SCREEN (With Level Popup)
// ---------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Initialize the confetti controller (duration of the blast)
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Helper: Convert Timestamp to "Time Ago"
  String getTimeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return "${diff.inDays}d ago";
    if (diff.inHours >= 1) return "${diff.inHours}h ago";
    if (diff.inMinutes >= 1) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  // Helper: Show the "Total Levels" Dialog
  void _showLevelMap(BuildContext context, int currentPoints, int currentLevel) {
    // 🎉 TRIGGER CONFETTI HERE 🎉
    _confettiController.play();

    final Map<int, int> levelMap = {1: 0, 2: 100, 3: 300, 4: 600, 5: 1000, 6: 2000};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardTheme.color,
        title: const Text("Earth Guardian Path"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: levelMap.entries.map((entry) {
            int lvl = entry.key;
            int pointsReq = entry.value;
            bool isUnlocked = currentLevel >= lvl;
            
            return ListTile(
              dense: true,
              leading: Icon(
                isUnlocked ? Icons.check_circle : Icons.lock_outline, 
                color: isUnlocked ? Colors.green : Colors.grey
              ),
              title: Text(
                "Level $lvl", 
                style: TextStyle(
                  fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                  color: isUnlocked ? Theme.of(ctx).textTheme.bodyLarge?.color : Colors.grey
                )
              ),
              trailing: Text("$pointsReq pts"),
            ).animate().slideX(begin: 0.2, end: 0, delay: (50 * lvl).ms); // Staggered list anim
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      floatingActionButton: FloatingActionButton.extended(
    onPressed: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RealtimeScanner()));
    },
    backgroundColor: Colors.deepPurpleAccent,
    foregroundColor: Colors.white,
    icon: const Icon(Icons.view_in_ar),
    label: const Text("View AR"),
  ),
      // 1. WRAP BODY IN A STACK
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
              
              final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
              int totalPoints = userData['totalPoints'] ?? 0;
              
              // Level Logic
              List<int> thresholds = [0, 100, 300, 600, 1000, 2000];
              int currentLevel = 1;
              int nextGoal = 100;

              for (int i = 0; i < thresholds.length; i++) {
                 if (totalPoints >= thresholds[i]) {
                    currentLevel = i + 1;
                    nextGoal = (i + 1 < thresholds.length) ? thresholds[i + 1] : thresholds.last;
                 }
              }
              
              int pointsNeeded = nextGoal - totalPoints;
              double progress = 0.0;
              if (currentLevel < thresholds.length) {
                 int prevGoal = thresholds[currentLevel - 1];
                 progress = (totalPoints - prevGoal) / (nextGoal - prevGoal);
              } else {
                 progress = 1.0;
                 pointsNeeded = 0;
              }

              return Column(
                children: [
                  // --- GAMIFICATION CARD ---
                  GestureDetector(
                    onTap: () => _showLevelMap(context, totalPoints, currentLevel),
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.6)]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("LEVEL $currentLevel", style: const TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text("Earth Guardian", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                                child: Row(children: [
                                  const Icon(Icons.info_outline, color: Colors.white, size: 16), 
                                  const SizedBox(width: 4), 
                                  Text("$totalPoints pts", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10), 
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0), 
                              minHeight: 8, 
                              backgroundColor: Colors.black12, 
                              valueColor: const AlwaysStoppedAnimation(Colors.white)
                            )
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight, 
                            child: Text(
                              pointsNeeded > 0 ? "$pointsNeeded pts to Level ${currentLevel + 1}" : "Max Level Reached!", 
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)
                            )
                          ),
                        ],
                      ),
                    ).animate()
                     .fade(duration: 800.ms)
                     .slideY(begin: -0.5, end: 0, curve: Curves.easeOutBack)
                     .shimmer(delay: 1000.ms, duration: 1500.ms),
                  ),

                  // --- HISTORY TITLE ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
                    child: Align(alignment: Alignment.centerLeft, child: Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
                  ),

                  // --- SCANS LIST ---
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('scans')
                          .where('userId', isEqualTo: user.uid)
                          // .orderBy('timestamp', descending: true) // Uncomment after indexing
                          .snapshots(),
                      builder: (context, scanSnap) {
                        if (!scanSnap.hasData) return const Center(child: CircularProgressIndicator());
                        final docs = scanSnap.data!.docs;

                        if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 50, color: Colors.grey[300]), const Text("No scans yet")]));

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            int score = data['carbon_score'] ?? 0;
                            Color scoreColor = score < 30 ? Colors.green : (score < 70 ? Colors.orange : Colors.red);
                            
                            Timestamp? t = data['timestamp'];
                            DateTime date = t != null ? t.toDate() : DateTime.now();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Hero(
                                  tag: "icon_${data['timestamp'] ?? index}", // Hero Tag
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: scoreColor.withOpacity(0.1), shape: BoxShape.circle),
                                    child: Icon(Icons.eco, color: scoreColor),
                                  ),
                                ),
                                title: Text(data['item_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(getTimeAgo(date)),
                                trailing: Text("$score", style: TextStyle(color: scoreColor, fontWeight: FontWeight.w900, fontSize: 18)),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(data: data))),
                              ),
                            ).animate(delay: (100 * index).ms).fadeIn().slideX(begin: 0.2, end: 0);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          
          // 2. THE CONFETTI WIDGET ON TOP
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive, // Boom!
            shouldLoop: false, 
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple], 
            createParticlePath: drawStar, // Custom Star Shape
          ),
        ],
      ),
    );
  }

  // Helper: Draw a Star Shape for Confetti
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (3.1415926535897932 / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = 360 / numberOfPoints;
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = 360;
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * 0.9 * -1 * (double.parse((1.0).toString()) * (step + halfDegreesPerStep) / 100), // Approximate for simple star
          halfWidth + externalRadius * 0.9 * (double.parse((1.0).toString()) * (step + halfDegreesPerStep) / 100));
    }
    path.addOval(Rect.fromCircle(center: Offset(halfWidth, halfWidth), radius: 4)); // Fallback simple dot if star math fails
    return path;
  }
}

// ---------------------------------------------------------
// 6. DETAIL SCREEN (Fixed Share Button)
// ---------------------------------------------------------
class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    int score = data['carbon_score'] ?? 0;
    Color color = score < 30 ? const Color(0xFF00E676) : (score < 70 ? Colors.orange : const Color(0xFFFF5252));

    return Scaffold(
      appBar: AppBar(title: Text(data['item_name'] ?? "Impact Card")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Image Area
            Container(
              height: 300,
              width: double.infinity,
              color: Theme.of(context).cardTheme.color,
              child: Stack(
                alignment: Alignment.center,
                children: [
                    Hero(
                        tag: "icon_${data['timestamp']}", 
                        child: Icon(score < 50 ? Icons.eco : Icons.cloud_off, size: 120, color: color.withOpacity(0.2))
                      ),                   
                      Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text("$score", style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: color)),
                       Text("CARBON SCORE", style: TextStyle(color: color, letterSpacing: 2, fontWeight: FontWeight.bold)),
                     ],
                   )
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(Icons.nature, "Eco-Analogy", data['tree_analogy'] ?? "No data", Colors.green),
                  const SizedBox(height: 16),
                  _detailRow(Icons.lightbulb, "AI Suggestion", data['nudge_text'] ?? "No suggestion", Colors.amber),
                  const SizedBox(height: 16),
                  _detailRow(Icons.category, "Category", data['shadow_type'] ?? "General", Colors.blue),
                  
                  const SizedBox(height: 40),
                  
                  // FIX: SHARE BUTTON (Opens Bottom Sheet)
                  SizedBox(
                    width: double.infinity, 
                    height: 55, 
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => Container(
                            height: 200,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Text("Share Impact Card", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _shareIcon(Icons.camera_alt, Colors.purple, "Instagram"),
                                    _shareIcon(Icons.message, Colors.green, "WhatsApp"),
                                    _shareIcon(Icons.copy, Colors.grey, "Copy"),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      }, 
                      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), 
                      icon: const Icon(Icons.share), 
                      label: const Text("SHARE IMPACT CARD")
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareIcon(IconData icon, Color color, String label) {
    return Column(children: [CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12))]);
  }

  Widget _detailRow(IconData icon, String title, String content, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(content, style: const TextStyle(fontSize: 16))]))
      ],
    );
  }
}

// ---------------------------------------------------------
// 7. TRAVEL SCREEN (With Database Update)
// ---------------------------------------------------------
class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});
  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  final _distanceController = TextEditingController();
  String _selectedMode = "Bus"; // Default to a medium option
  bool _isSaving = false;

  // Emissions per KM (kg)
  final Map<String, double> _emissionFactors = {
    "Car": 0.192,
    "Bus": 0.105,
    "Motorbike": 0.103,
    "Train": 0.041,
    "Bicycle": 0.0,
    "Walk": 0.0
  };

  // --- GAMIFIED POPUP ---
  void _showRewardDialog(double savedCo2, int earnedPoints, String mode) {
    String message = "Good job logging your trip!";
    IconData icon = Icons.thumb_up;
    Color color = Colors.blue;

    if (savedCo2 > 0) {
      message = "You saved ${savedCo2.toStringAsFixed(2)}kg of CO2 compared to driving!";
      icon = Icons.eco;
      color = Colors.green;
    } else if (mode == "Car") {
      message = "Next time, try a bus or train to earn more points!";
      icon = Icons.directions_car;
      color = Colors.orange;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 50, color: color),
            ),
            const SizedBox(height: 20),
            Text("+$earnedPoints PTS", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                child: const Text("AWESOME!"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _logTravel() async {
    final user = FirebaseAuth.instance.currentUser;
    double dist = double.tryParse(_distanceController.text) ?? 0.0;
    
    if (dist <= 0 || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid distance")));
      return;
    }

    setState(() => _isSaving = true);
    
    // 1. Calculate Emissions
    double myEmission = dist * (_emissionFactors[_selectedMode] ?? 0.0);
    double carEmission = dist * 0.192; // Baseline
    double savedCo2 = (carEmission - myEmission).clamp(0.0, 999.0);

    // 2. Gamification Math
    // Base points (10) + Bonus for saving CO2 (10 pts per kg saved)
    int earnedPoints = (10 + (savedCo2 * 20)).toInt();
    // Cap max points per trip to prevent cheating
    if (earnedPoints > 150) earnedPoints = 150; 
    
    // Invert Score for visual (Lower Carbon = Higher Visual Score in the list)
    int visualScore = (100 - (myEmission * 10)).toInt().clamp(0, 100);

    try {
      // 3. Save to DB
      await FirebaseFirestore.instance.collection('scans').add({
        'item_name': "$_selectedMode Trip", 
        'carbon_score': visualScore, 
        'shadow_type': "Travel", 
        'nudge_text': savedCo2 > 0.1 ? "Great choice! You beat the car emission." : "Consider carpooling next time.", 
        'tree_analogy': "Emitted ${myEmission.toStringAsFixed(2)} kg CO2", 
        'userId': user.uid, 
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'totalPoints': FieldValue.increment(earnedPoints)
      });

      if (!mounted) return;
      
      // 4. Show Reward
      _distanceController.clear();
      setState(() => _isSaving = false);
      _showRewardDialog(savedCo2, earnedPoints, _selectedMode);

    } catch (e) { 
      setState(() => _isSaving = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Travel Log")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("How did you move today?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Transport Icons Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _emissionFactors.keys.map((mode) {
                bool isSelected = _selectedMode == mode;
                IconData icon;
                switch(mode) {
                  case "Car": icon = Icons.directions_car; break;
                  case "Bus": icon = Icons.directions_bus; break;
                  case "Train": icon = Icons.train; break;
                  case "Bicycle": icon = Icons.directions_bike; break;
                  case "Walk": icon = Icons.directions_walk; break;
                  default: icon = Icons.motorcycle;
                }

                return GestureDetector(
                  onTap: () => setState(() => _selectedMode = mode),
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [if(isSelected) BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 8)],
                      border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3))
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 30),
                        const SizedBox(height: 5),
                        Text(mode, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                // At the closing parenthesis of the GestureDetector container:
              ).animate()
              .fade(duration: 800.ms)
              .slideY(begin: -0.5, end: 0, curve: Curves.easeOutBack) // Bouncy slide from top
              .shimmer(delay: 1000.ms, duration: 1500.ms); // Shiny reflection effect
              }).toList(),
            ),

            const SizedBox(height: 30),
            
            TextField(
              controller: _distanceController, 
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(
                labelText: "Distance (km)", 
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, 
              height: 55, 
              child: ElevatedButton(
                onPressed: _isSaving ? null : _logTravel, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ), 
                child: Text(_isSaving ? "CALCULATING..." : "LOG TRIP & EARN POINTS")
              )
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 8. SCANNER SCREEN (With Gemini & Database Update)
// ---------------------------------------------------------

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // 📸 THE CORE FUNCTION
  Future<void> _analyzeImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo == null) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    try {
      // 1. Convert Image & Call AI
      final bytes = await photo.readAsBytes();
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
                "text": "Identify object. Estimate Carbon Footprint Score (0-100). "
                        "Return ONLY raw JSON: {'item_name': 'String', 'carbon_score': Int, 'shadow_type': 'String', 'nudge_text': 'String'}"
              }, 
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image}
              }
            ]
          }]
        }),
      );

      if (response.statusCode == 200) {
        // 2. Parse Data
        final jsonResponse = jsonDecode(response.body);
        String finalText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        finalText = finalText.replaceAll("```json", "").replaceAll("```", "").trim();
        final Map<String, dynamic> parsedData = jsonDecode(finalText);

        // 3. Stabilization Logic
        String name = parsedData['item_name'] ?? "Unknown Item";
        int baseScore = parsedData['carbon_score'] ?? 50;
        int nameOffset = (name.hashCode % 11) - 5; 
        int consistentScore = (baseScore + nameOffset).clamp(0, 100);
        parsedData['carbon_score'] = consistentScore;
        
        // 4. 🚀 NAVIGATE IMMEDIATELY (Don't wait for Firebase!)
        if (mounted) {
           setState(() => _isLoading = false);
           Navigator.push(
             context, 
             MaterialPageRoute(builder: (_) => DetailScreen(data: parsedData))
           );
        }

        // 5. Save to Firebase in Background (Fire & Forget)
        // We do NOT use 'await' here so the UI doesn't freeze.
        int earnedPoints = (100 - consistentScore).clamp(10, 100);
        
        FirebaseFirestore.instance.collection('scans').add({
          ...parsedData, 
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp()
        });

        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'totalPoints': FieldValue.increment(earnedPoints)
        }).catchError((e) => print("Background save error: $e")); // Log errors silently

      } else {
        throw Exception("API Error");
      }
    } catch (e) {
      print("Scan Error: $e");
      setState(() => _isLoading = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Try scanning again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: _isLoading 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text("Analyzing Molecular Structure...", style: TextStyle(color: Theme.of(context).primaryColor)),
                  const SizedBox(height: 5),
                  const Text("Calculating Carbon Shadow...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Scanner Icon
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1), 
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 2)
                    ),
                    child: Icon(Icons.qr_code_scanner, size: 80, color: Theme.of(context).primaryColor),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.05, duration: 2.seconds) // Breathing effect
                  .shimmer(duration: 2.seconds, color: Colors.white54), // Shiny scan effect

                  const SizedBox(height: 40),
                  
                  const Text(
                    "Carbon Scanner Ready", 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Point your camera at any object to reveal its invisible carbon impact.", 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)
                    ),
                  ),
                  
                  const SizedBox(height: 50),

                  // The Main Button
                  ElevatedButton.icon(
                    onPressed: _analyzeImage, 
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("INITIATE SCAN"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 10,
                      shadowColor: Theme.of(context).primaryColor.withOpacity(0.5),
                    ), 
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds) // Pulse invitation
                  .elevation(begin: 5, end: 15),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 9. LEADERBOARD SCREEN (REAL DATA FROM FIREBASE)
// ---------------------------------------------------------
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Leaderboard")),
      body: StreamBuilder<QuerySnapshot>(
        // Query users sorted by totalPoints
        stream: FirebaseFirestore.instance.collection('users').orderBy('totalPoints', descending: true).limit(50).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isMe = data['uid'] == myUid;
              
              return Card(
                elevation: isMe ? 4 : 1,
                color: isMe ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isMe ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index == 0 ? Colors.amber : (index == 1 ? Colors.grey[400] : (index == 2 ? Colors.orange[300] : Colors.transparent)),
                    child: Text("${index + 1}", style: TextStyle(color: index < 3 ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(data['displayName'] ?? "Anonymous", style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                  subtitle: isMe ? const Text("This is you!", style: TextStyle(fontSize: 10, color: Colors.blue)) : null,
                  trailing: Text("${data['totalPoints'] ?? 0} pts", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// 10. PROFILE SCREEN
// ---------------------------------------------------------
// ---------------------------------------------------------
// REPLACEMENT: PROFILE SCREEN (With Theme Toggle)
// ---------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"), 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red), 
            onPressed: () => FirebaseAuth.instance.signOut()
          )
        ]
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50, 
                  backgroundColor: Theme.of(context).primaryColor, 
                  child: Text(
                    data['displayName']?[0] ?? "U", 
                    style: const TextStyle(fontSize: 40, color: Colors.white)
                  )
                ),
                const SizedBox(height: 20),
                
                // Name & Email
                Text(data['displayName'] ?? "User", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(user.email ?? "", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                // Score Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color, 
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text(
                    "Total Score: ${data['totalPoints'] ?? 0}", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)
                  ),
                ),
                
                // 👇 ADDED: THEME TOGGLE BUTTON 👇
                const SizedBox(height: 40),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier, // Listens to the global variable
                  builder: (context, mode, child) {
                    bool isLight = mode == ThemeMode.light;
                    return ElevatedButton.icon(
                      onPressed: () {
                        // Toggle Logic
                        themeNotifier.value = isLight ? ThemeMode.dark : ThemeMode.light;
                      },
                      icon: Icon(isLight ? Icons.dark_mode : Icons.light_mode),
                      label: Text(isLight ? "Switch to Dark Mode" : "Switch to Light Mode"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        backgroundColor: isLight ? Colors.grey[800] : Colors.amber,
                        foregroundColor: isLight ? Colors.white : Colors.black,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// NEW SCREEN: AR IMPACT VISUALIZER
// ---------------------------------------------------------

// ---------------------------------------------------------
// REPLACEMENT: AR SCREEN (The "Hologram" Hack)
// --------------------------
// ---------------------------------------------------------
// NEW: AR SHADOW VISUALIZER
// ---------------------------------------------------------
class ArScreen extends StatefulWidget {
  final int score; // We pass the score here!
  
  // Default to 50 if opened without a scan
  const ArScreen({super.key, this.score = 50}); 

  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  @override
  Widget build(BuildContext context) {
    // 1. Determine the "Mode" based on score
    bool isHighImpact = widget.score > 60;  // Bad (Red/Black)
    bool isLowImpact = widget.score < 30;   // Good (Green/Gold)
    // Else: Medium (Grey/Orange)

    Color dominantColor = isHighImpact ? Colors.red.shade900 : (isLowImpact ? Colors.greenAccent : Colors.orange);
    String statusText = isHighImpact ? "CRITICAL CARBON LEVEL" : (isLowImpact ? "ECO-FRIENDLY" : "MODERATE IMPACT");

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // LAYER 1: The Camera Feed (Simulated)
          Image.network(
            "https://images.unsplash.com/photo-1550989460-0adf9ea622e2?q=80&w=1000&auto=format&fit=crop", // A "Tech" background texture
            fit: BoxFit.cover,
            color: isHighImpact ? Colors.black.withOpacity(0.7) : Colors.black.withOpacity(0.3), // Darker if bad
            colorBlendMode: BlendMode.darken,
          ),

          // LAYER 2: The "Shadow" / "Glow" Effect
          // This is the core visual warning
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // THE SHADOW LOGIC:
                boxShadow: [
                  BoxShadow(
                    color: dominantColor.withOpacity(isHighImpact ? 0.6 : 0.4), 
                    blurRadius: isHighImpact ? 100 : 60, // Smoke is blurry, Glow is tighter
                    spreadRadius: isHighImpact ? 50 : 20, // Smoke spreads more
                  ),
                ],
                // If High Impact, we add a "Smoke" gradient
                gradient: isHighImpact 
                  ? RadialGradient(colors: [Colors.black.withOpacity(0.8), Colors.transparent]) 
                  : RadialGradient(colors: [Colors.white.withOpacity(0.2), Colors.transparent]),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: isHighImpact ? 1.5 : 1.1, duration: isHighImpact ? 1.seconds : 3.seconds) // Bad items "pulse" fast
          ),

          // LAYER 3: The Hologram Icon
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHighImpact ? Icons.warning_amber_rounded : (isLowImpact ? Icons.eco : Icons.info_outline),
                  size: 100,
                  color: isHighImpact ? Colors.red : (isLowImpact ? Colors.white : Colors.amber),
                )
                .animate()
                .shake(hz: isHighImpact ? 5 : 0) // Shake if dangerous!
                .fade(duration: 1.seconds),
                
                const SizedBox(height: 200), // Push text down
              ],
            ),
          ),

          // LAYER 4: The HUD (Heads Up Display)
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border.all(color: dominantColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: dominantColor, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 2,
                      fontSize: 18
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Carbon Shadow Density: ${widget.score}%",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  // Progress Bar
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: widget.score / 100,
                    backgroundColor: Colors.grey[900],
                    valueColor: AlwaysStoppedAnimation(dominantColor),
                    minHeight: 5,
                  )
                ],
              ),
            ).animate().slideY(begin: 1.0, end: 0),
          ),
          
          // Back Button
          Positioned(
            top: 50, left: 20,
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          )
        ],
      ),
    );
  }
}