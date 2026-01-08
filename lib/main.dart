import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'dart:ui';
import 'dart:math';
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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// ⚠️ YOUR API KEY
const String apiKey = "AIzaSyDu0fv0DEOHisIfgAM9sxJ5Qx0AJ_a_RCw";

// Global Theme Notifier for Toggle
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    print("Firebase Setup Error: $e");
  }
  runApp(const CarbonTrackerApp());
}

// ---------------------------------------------------------
// 1. THEME DEFINITIONS
// ---------------------------------------------------------
class CyberTheme {
  // Dark Mode Colors
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF121212);
  static const Color textMain = Color(0xFFE0E0E0);
  
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextMain = Color(0xFF1C1C1E);

  // Brand Colors
  static const Color primary = Color(0xFF00FFC2); // Cyan
  static const Color secondary = Color(0xFFD500F9); // Purple
  static const Color danger = Color(0xFFFF2E2E); // Red

  static TextStyle techText(
      {double size = 14,
      FontWeight weight = FontWeight.normal,
      Color? color,
      double spacing = 1.0}) {
    return TextStyle(
      fontFamily: 'Courier',
      fontSize: size,
      fontWeight: weight,
      color: color, 
      letterSpacing: spacing,
    );
  }
}

class CarbonTrackerApp extends StatelessWidget {
  const CarbonTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Carbon Shadow Protocol',
          themeMode: mode, 
          
          // LIGHT THEME
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: CyberTheme.lightBackground,
            primaryColor: CyberTheme.primary,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: CyberTheme.lightTextMain),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: CyberTheme.techText(
                  size: 20, weight: FontWeight.bold, color: Colors.black, spacing: 2.0),
              iconTheme: const IconThemeData(color: Colors.black),
              actionsIconTheme: const IconThemeData(color: Colors.black),
            ),
            colorScheme: const ColorScheme.light(
              primary: CyberTheme.primary,
              secondary: CyberTheme.secondary,
              surface: CyberTheme.lightSurface,
              onSurface: CyberTheme.lightTextMain,
            ),
          ),

          // DARK THEME
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: CyberTheme.background,
            primaryColor: CyberTheme.primary,
             textTheme: const TextTheme(
              bodyMedium: TextStyle(color: CyberTheme.textMain),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: CyberTheme.techText(
                  size: 20, weight: FontWeight.bold, color: CyberTheme.primary, spacing: 2.0),
              iconTheme: const IconThemeData(color: CyberTheme.primary),
              actionsIconTheme: const IconThemeData(color: CyberTheme.primary),
            ),
            colorScheme: const ColorScheme.dark(
              primary: CyberTheme.primary,
              secondary: CyberTheme.secondary,
              surface: CyberTheme.surface,
              onSurface: CyberTheme.textMain,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// 2. NATIVE PARTICLE ENGINE & BACKGROUND (NO GRIDS)
// ---------------------------------------------------------
class CyberBackground extends StatefulWidget {
  final Widget child;
  const CyberBackground({super.key, required this.child});

  @override
  State<CyberBackground> createState() => _CyberBackgroundState();
}

class _CyberBackgroundState extends State<CyberBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle(
        x: _rng.nextDouble() * size.width,
        y: _rng.nextDouble() * size.height,
        vx: _rng.nextDouble() * 1.0 - 0.5,
        vy: _rng.nextDouble() * 1.0 - 0.5,
        size: _rng.nextDouble() * 3 + 1,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Layer 0: Adaptive Background Gradient
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: isDark
                  ? [const Color(0xFF1A1A2E), CyberTheme.background]
                  : [Colors.white, const Color(0xFFE0E0E0)],
            ),
          ),
        ),

        // Layer 1: Native Particle System
        LayoutBuilder(builder: (context, constraints) {
          _initParticles(Size(constraints.maxWidth, constraints.maxHeight));
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: ParticlePainter(
                    _particles, 
                    isDark ? CyberTheme.primary : Colors.black
                ),
              );
            },
          );
        }),

        // NOTE: GridPainter removed as requested

        // Layer 3: Content
        SafeArea(child: widget.child),
      ],
    );
  }
}

class Particle {
  double x, y, vx, vy, size;
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.size});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;
  ParticlePainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.3);
    final linePaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1;

    for (var p in particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0 || p.x > size.width) p.vx *= -1;
      if (p.y < 0 || p.y > size.height) p.vy *= -1;
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      for (var other in particles) {
        double dx = p.x - other.x;
        double dy = p.y - other.y;
        if (sqrt(dx * dx + dy * dy) < 100) {
          canvas.drawLine(Offset(p.x, p.y), Offset(other.x, other.y), linePaint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------
// 3. REUSABLE UI WIDGETS
// ---------------------------------------------------------
class CyberCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool isGlowing;

  const CyberCard(
      {super.key,
      required this.child,
      this.onTap,
      this.borderColor,
      this.isGlowing = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = borderColor ?? (isDark ? CyberTheme.primary : Colors.black);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: border.withOpacity(isGlowing ? 0.8 : 0.3), width: 1),
          boxShadow: isGlowing
              ? [BoxShadow(color: border.withOpacity(0.3), blurRadius: 15, spreadRadius: 1)]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Adaptive Background: Darker in dark mode, visible white/grey in light mode
                color: isDark 
                    ? CyberTheme.surface.withOpacity(0.4) 
                    : Colors.white.withOpacity(0.85),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    isDark ? Colors.white.withOpacity(0.01) : Colors.grey.shade100
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class CyberButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;

  const CyberButton(
      {super.key,
      required this.text,
      required this.onPressed,
      this.isLoading = false,
      this.color,
      this.icon});

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? CyberTheme.primary;
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: btnColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.black, 
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(text.toUpperCase(),
                      style: CyberTheme.techText(
                          weight: FontWeight.bold, spacing: 1.5, color: Colors.black)),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. AUTH & SCREENS
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("IDENTIFICATION REQUIRED. ENTER NAME.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim());
      } else {
        UserCredential cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim());

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'uid': cred.user!.uid,
          'email': _emailController.text.trim(),
          'displayName': _nameController.text.trim(),
          'totalPoints': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? "ACCESS DENIED"),
          backgroundColor: CyberTheme.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInput(
      TextEditingController controller, String label, IconData icon,
      {bool isPass = false}) {
    // Logic to ensure visibility in light mode login
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5), // Keep login dark even in light mode for contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberTheme.primary.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        style: CyberTheme.techText(color: Colors.white),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: TextStyle(color: CyberTheme.primary.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: CyberTheme.primary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hexagon_outlined, size: 80, color: CyberTheme.primary)
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 10.seconds),
                const SizedBox(height: 20),
                Text("CARBON LENS",
                    style: CyberTheme.techText(
                        size: 24, weight: FontWeight.bold, spacing: 4, color: CyberTheme.primary)),
                const SizedBox(height: 40),
                if (!_isLogin)
                  _buildInput(_nameController, "AGENT NAME", Icons.badge),
                _buildInput(_emailController, "EMAIL ID", Icons.alternate_email),
                _buildInput(_passwordController, "PASSWORD", Icons.lock_outline,
                    isPass: true),
                const SizedBox(height: 24),
                CyberButton(
                    text: _isLogin ? "LOG IN" : "SIGN UP",
                    onPressed: _submit,
                    isLoading: _isLoading),
                const SizedBox(height: 16),
                TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? "> Don't have an account? SIGN UP here"
                          : "> Has access? LOG IN here",
                      style: CyberTheme.techText(
                          color: Colors.grey, size: 12),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow behind the nav bar if transparent
      
      // 🌟 CHANGED: Using a Stack to float the button over ALL tabs
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Current Tab Page
          _pages[_currentIndex],

          // 2. The Global "View AR" Button
          Positioned(
            bottom: 140, // ⬆️ ADJUST HEIGHT HERE (100 = low, 300 = high)
            right: 20,   // Keep it on the right side
            child: FloatingActionButton(
              heroTag: "global_ar_scanner_btn", // Unique tag prevents hero errors
              elevation: 10,
              backgroundColor: CyberTheme.secondary,
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const RealtimeScanner())
                );
              },
              child: const Icon(Icons.view_in_ar, color: Colors.white),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withOpacity(0.9),
          border: Border(top: BorderSide(color: CyberTheme.primary.withOpacity(0.2))),
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.transparent,
          indicatorColor: CyberTheme.primary.withOpacity(0.2),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.grid_view, color: Colors.grey),
                selectedIcon: Icon(Icons.grid_view, color: CyberTheme.primary),
                label: "HUD"),
            NavigationDestination(
                icon: Icon(Icons.commute, color: Colors.grey),
                selectedIcon: Icon(Icons.commute, color: CyberTheme.primary),
                label: "TRAVEL"),
            NavigationDestination(
                icon: Icon(Icons.center_focus_weak, color: Colors.grey),
                selectedIcon: Icon(Icons.center_focus_strong, color: CyberTheme.primary),
                label: "SCAN"),
            NavigationDestination(
                icon: Icon(Icons.emoji_events, color: Colors.grey),
                selectedIcon: Icon(Icons.emoji_events, color: CyberTheme.primary),
                label: "RANK"),
            NavigationDestination(
                icon: Icon(Icons.fingerprint, color: Colors.grey),
                selectedIcon: Icon(Icons.fingerprint, color: CyberTheme.primary),
                label: "ID"),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 5. DASHBOARD
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
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String getTimeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return "${diff.inDays}D AGO";
    if (diff.inHours >= 1) return "${diff.inHours}H AGO";
    return "${diff.inMinutes}M AGO";
  }

  void _showLevelMap(BuildContext context, int currentPoints, int currentLevel) {
    _confettiController.play();
    final Map<int, int> levelMap = {
      1: 0,
      2: 100,
      3: 300,
      4: 600,
      5: 1000,
      6: 2000
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardTheme.color,
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: CyberTheme.primary),
            borderRadius: BorderRadius.circular(20)),
        title: Text("GUARDIAN PROGRESSION",
            style: CyberTheme.techText(color: CyberTheme.primary, weight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: levelMap.entries.map((entry) {
            int lvl = entry.key;
            int pointsReq = entry.value;
            bool isUnlocked = currentLevel >= lvl;

            return ListTile(
              dense: true,
              leading: Icon(
                  isUnlocked ? Icons.lock_open : Icons.lock,
                  color: isUnlocked ? CyberTheme.primary : Colors.grey),
              title: Text("LEVEL $lvl // SECTOR $lvl",
                  style: TextStyle(
                      color: isUnlocked ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey,
                      fontFamily: 'Courier')),
              trailing: Text("$pointsReq PTS",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: CyberBackground(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              children: [
                AppBar(title: const Text("COMMAND CENTER")),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .snapshots(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Inside DashboardScreen StreamBuilder
                      final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};

                      // Default to 100 if the field is missing
                      int totalPoints = userData['totalPoints'] ?? 100; 

                      // OPTIONAL: Auto-reset if they hit 0 or negative (Game Over logic)
                      if (totalPoints <= 0) {
                        totalPoints = 0; // Or show "Game Over"
                      }

                      List<int> thresholds = [0, 100, 300, 600, 1000, 2000];
                      int currentLevel = 1;
                      int nextGoal = 100;
                      for (int i = 0; i < thresholds.length; i++) {
                        if (totalPoints >= thresholds[i]) {
                          currentLevel = i + 1;
                          nextGoal = (i + 1 < thresholds.length)
                              ? thresholds[i + 1]
                              : thresholds.last;
                        }
                      }
                      int pointsNeeded = nextGoal - totalPoints;
                      double progress = 0.0;
                      if (currentLevel < thresholds.length) {
                        int prevGoal = thresholds[currentLevel - 1];
                        progress =
                            (totalPoints - prevGoal) / (nextGoal - prevGoal);
                      } else {
                        progress = 1.0;
                        pointsNeeded = 0;
                      }

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _showLevelMap(context, totalPoints, currentLevel),
                            child: CyberCard(
                              isGlowing: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("CURRENT CLEARANCE",
                                              style: CyberTheme.techText(
                                                  size: 10,
                                                  color: CyberTheme.primary)),
                                          Text("LEVEL $currentLevel",
                                              style: CyberTheme.techText(
                                                  size: 28,
                                                  weight: FontWeight.bold,
                                                  color: textColor)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: CyberTheme.primary),
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text("$totalPoints PTS",
                                            style: CyberTheme.techText(
                                                color: CyberTheme.primary,
                                                weight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Stack(
                                    children: [
                                      Container(height: 10, color: Colors.black),
                                      AnimatedContainer(
                                        duration: 1000.ms,
                                        height: 10,
                                        width: MediaQuery.of(context).size.width *
                                            progress.clamp(0.0, 1.0) *
                                            0.8,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [
                                            CyberTheme.primary,
                                            CyberTheme.secondary
                                          ]),
                                          boxShadow: [
                                            BoxShadow(
                                                color: CyberTheme.primary
                                                    .withOpacity(0.5),
                                                blurRadius: 10)
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                          pointsNeeded > 0
                                              ? "Level Up In $pointsNeeded PTS"
                                              : "MAXIMUM SYNC REACHED!",
                                          style: CyberTheme.techText(
                                              size: 10, color: textColor))),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text("> RECENT LOGS",
                                    style: CyberTheme.techText(
                                        size: 16, weight: FontWeight.bold, color: textColor))),
                          ),

                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('scans')
                                  .where('userId', isEqualTo: user.uid)
                                  .snapshots(),
                              builder: (context, scanSnap) {
                                if (!scanSnap.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                final docs = scanSnap.data!.docs;
                                if (docs.isEmpty) {
                                  return Center(
                                      child: Text("NO DATA FOUND",
                                          style: CyberTheme.techText(
                                              color: Colors.grey)));
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 250),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final data = docs[index].data()
                                        as Map<String, dynamic>;
                                    int score = data['carbon_score'] ?? 0;
                                    Color scoreColor = score < 30
                                        ? CyberTheme.primary
                                        : (score < 70
                                            ? Colors.orange
                                            : CyberTheme.danger);
                                    Timestamp? t = data['timestamp'];
                                    DateTime date =
                                        t != null ? t.toDate() : DateTime.now();

                                    return CyberCard(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  DetailScreen(data: data))),
                                      borderColor: scoreColor,
                                      child: Row(
                                        children: [
                                          Icon(Icons.qr_code_2,
                                              color: scoreColor, size: 30),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    (data['item_name'] ??
                                                            "UNKNOWN")
                                                        .toUpperCase(),
                                                    style: CyberTheme.techText(
                                                        weight: FontWeight.bold, color: textColor)),
                                                Text(getTimeAgo(date),
                                                    style: CyberTheme.techText(
                                                        size: 10,
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                          Text("$score",
                                              style: TextStyle(
                                                  color: scoreColor,
                                                  fontSize: 24,
                                                  fontFamily: 'Courier',
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ).animate().slideX();
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                CyberTheme.primary,
                CyberTheme.secondary,
                Colors.white
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 6. DETAIL SCREEN
// ---------------------------------------------------------
class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    int score = data['carbon_score'] ?? 0;
    Color color = score < 30
        ? CyberTheme.primary
        : (score < 70 ? Colors.orange : CyberTheme.danger);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppBar(title: const Text("OBJECT ANALYSIS")),
      body: CyberBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Container(
                  height: 250,
                  width: 250,
                  margin: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10)
                    ],
                    gradient: RadialGradient(colors: [
                      color.withOpacity(0.2),
                      Colors.transparent
                    ]),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hub, size: 60, color: color)
                          .animate(onPlay: (c) => c.repeat())
                          .rotate(duration: 10.seconds),
                      Text("$score",
                          style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontFamily: 'Courier')),
                      Text("CARBON\nDENSITY",
                          textAlign: TextAlign.center,
                          style: CyberTheme.techText(size: 10, color: color)),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CyberCard(
                      borderColor: color,
                      child: Column(
                        children: [
                          _detailRow("IDENTIFIER", data['item_name'], color, textColor),
                          Divider(color: textColor?.withOpacity(0.2)),
                          _detailRow("CATEGORY", data['shadow_type'], textColor, textColor),
                          Divider(color: textColor?.withOpacity(0.2)),
                          _detailRow("ANALYSIS", data['nudge_text'], Colors.blueGrey.shade200, textColor),
                          Divider(color: textColor?.withOpacity(0.2)),
                          _detailRow("EQUIVALENT", data['tree_analogy'], CyberTheme.secondary, textColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 👇 NEW BUTTON: VIEW CARBON SHADOW 👇
                    CyberButton(
                      text: "VIEW CARBON SHADOW (AR)",
                      icon: Icons.view_in_ar,
                      color: color,
                      onPressed: () {
                        // Pass the specific score to the AR screen
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => ArScreen(score: score)
                          )
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    CyberButton(
                      text: "TRANSMIT DATA (SHARE)",
                      icon: Icons.share,
                      color: Colors.red.shade900,
                      onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Transmitted to Network")));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value, Color? valColor, Color? defaultColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: CyberTheme.techText(size: 12, color: Colors.grey))),
          Expanded(
              child: Text(value ?? "N/A",
                  style: CyberTheme.techText(color: valColor ?? defaultColor))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 7. TRAVEL SCREEN (Fixed for iOS Keyboard Dismissal)
// ---------------------------------------------------------
class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});
  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  final _distanceController = TextEditingController();
  String _selectedMode = "Bus";
  bool _isSaving = false;
  final Map<String, double> _emissionFactors = {
    "Car": 0.192,
    "Bus": 0.105,
    "Train": 0.041,
    "Bicycle": 0.0,
    "Walk": 0.0
  };

  Future<void> _logTravel() async {
    final user = FirebaseAuth.instance.currentUser;
    double dist = double.tryParse(_distanceController.text) ?? 0.0;
    if (dist <= 0 || user == null) return;

    // Dismiss keyboard programmatically before saving
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);
    double myEmission = dist * (_emissionFactors[_selectedMode] ?? 0.0);
    int earnedPoints = (10 + ((dist * 0.192 - myEmission) * 20)).toInt().clamp(10, 150);
    int visualScore = (100 - (myEmission * 10)).toInt().clamp(0, 100);

    await FirebaseFirestore.instance.collection('scans').add({
      'item_name': "$_selectedMode Transport",
      'carbon_score': visualScore,
      'shadow_type': "Travel",
      'nudge_text': "Mobility Log: $dist km via $_selectedMode",
      'tree_analogy': "Emission: ${myEmission.toStringAsFixed(2)} kg",
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'totalPoints': FieldValue.increment(earnedPoints)});

    if (mounted) {
      setState(() => _isSaving = false);
      _distanceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("TRIP LOGGED. +$earnedPoints PTS"),
          backgroundColor: CyberTheme.primary));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Wrap entire Scaffold body in GestureDetector to allow tap-to-dismiss
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("MOBILITY LOG"),
          leading: defaultTargetPlatform == TargetPlatform.iOS
              ? IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  tooltip: "Hide Keyboard",
                  onPressed: () => FocusScope.of(context).unfocus(),
                )
              : null, 
        ),
        body: CyberBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("> SELECT VECTOR", style: CyberTheme.techText(color: Colors.grey)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _emissionFactors.keys.map((mode) {
                    bool isSelected = _selectedMode == mode;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMode = mode),
                      child: AnimatedContainer(
                        duration: 300.ms,
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CyberTheme.primary.withOpacity(0.2)
                              : Colors.transparent,
                          border: Border.all(
                              color: isSelected
                                  ? CyberTheme.primary
                                  : Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: CyberTheme.primary.withOpacity(0.2),
                                      blurRadius: 10)
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              mode == "Car"
                                  ? Icons.directions_car
                                  : mode == "Bus"
                                      ? Icons.directions_bus
                                      : mode == "Train"
                                          ? Icons.train
                                          : mode == "Bicycle"
                                              ? Icons.directions_bike
                                              : Icons.directions_walk,
                              color: isSelected ? CyberTheme.primary : Colors.grey,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(mode.toUpperCase(),
                                style: TextStyle(
                                    color: isSelected
                                        ? CyberTheme.primary
                                        : Colors.grey,
                                    fontSize: 10,
                                    fontFamily: 'Courier'))
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? Colors.grey.withOpacity(0.3) : Colors.black12),
                  ),
                  child: TextField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    // 3. Ensuring the input action is "Done" helps on some devices
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: "DISTANCE (KM)",
                      labelStyle: TextStyle(
                          color: isDark ? Colors.grey : Colors.grey.shade600),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.timeline, color: Colors.grey),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                CyberButton(
                    text: "EXECUTE LOG",
                    onPressed: _isSaving ? null : _logTravel,
                    isLoading: _isSaving),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ---------------------------------------------------------
// 8. SCANNER (FIXED INITIALIZE BUTTON)
// ---------------------------------------------------------
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // 📍 LOCATION HELPER
  Future<String> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if GPS is on
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "Unknown Location";

    // 2. Check Permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return "Unknown Location";
    }
    if (permission == LocationPermission.deniedForever) return "Unknown Location";

    // 3. Get Position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low // Low is faster and enough for City level
      );

      // 4. Convert to Address (Reverse Geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.locality}, ${place.country}"; // Returns "Kolkata, India"
      }
    } catch (e) {
      print("Location Error: $e");
    }
    return "Unknown Location";
  }

  Future<void> _analyzeImage() async {
// ⚡ OPTIMIZED: Resize to 600px wide and lower quality to 50%
// This reduces file size from ~5MB to ~50KB (100x smaller!)
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera, 
      maxWidth: 600, 
      maxHeight: 600, 
      imageQuality: 50
    );
    if (photo == null) return;

    setState(() => _isLoading = true);
    
    // 👇 1. GET LOCATION BEFORE AI CALL
    String userLocation = await _getCurrentLocation(); 
    // (Optional: Show a toast like "Scanning from Kolkata...")

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final bytes = await photo.readAsBytes();
      String base64Image = base64Encode(bytes);
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey.trim()}');

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [{
              "parts": [
                {
                  // 👇 UPDATED PROMPT WITH LOCATION CONTEXT
                  "text": "I am currently in $userLocation. Identify this object. "
                          "Estimate Carbon Footprint Score (0-100) considering local availability and transport emissions. "
                          "For example, if I am in India and this is a Mango, score is low. If I am in Canada, score is high. "
                          "Return ONLY raw JSON: {'item_name': 'String', 'carbon_score': Int, 'shadow_type': 'String', 'nudge_text': 'String', 'tree_analogy': 'String'}"
                },
                {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}
              ]
            }]
          }));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String finalText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        finalText = finalText.replaceAll("```json", "").replaceAll("```", "").trim();
        final Map<String, dynamic> parsedData = jsonDecode(finalText);
        
        // ✅ NEW LOGIC: Trust Gemini's Location-Aware Score
        // The AI now calculates the score based on your prompt ("I am in Kolkata...")
        int aiScore = parsedData['carbon_score'] ?? 50; // Default to 50 if AI fails

        // Optional: Add a tiny bit of natural variation (±5 points) 
        // so two scans of the same object feel "alive" but consistent.
        int variation = Random().nextInt(6) - 3; // Generates -3 to +3
        int finalScore = (aiScore + variation).clamp(0, 100);

        parsedData['carbon_score'] = finalScore;

        // --- 2. FAST NAVIGATION ---
        if (mounted) {
           setState(() => _isLoading = false);
           Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(data: parsedData)));
        }

        // --- 3. CARBON BUDGET DEDUCTION ---
        // Save scan
        await FirebaseFirestore.instance.collection('scans').add({
          ...parsedData,
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp()
        });

        // Subtract points from user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'totalPoints': FieldValue.increment(-finalScore)});
            
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("VISUAL SCANNER")),
      body: CyberBackground(
        child: Center(
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: CyberTheme.primary),
                    const SizedBox(height: 20),
                    Text("ANALYZING MATTER...",
                        style: CyberTheme.techText(color: CyberTheme.primary))
                  ],
                )
              : GestureDetector(
                  onTap: _analyzeImage,
                  // --- FIXED BUTTON STYLING ---
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Light mode: Solid white with border. Dark mode: Translucent black.
                      color: isDark ? Colors.black.withOpacity(0.5) : Colors.white,
                      border: Border.all(
                          color: isDark ? CyberTheme.primary : Colors.black, 
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: isDark ? CyberTheme.primary.withOpacity(0.3) : Colors.black12,
                            blurRadius: 30,
                            spreadRadius: 5)
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, 
                             size: 90, 
                             // Icon color logic
                             color: isDark ? Colors.white : Colors.black), 
    
                        const SizedBox(height: 10),
                        Text("INITIATE SCAN",
                            style: CyberTheme.techText(
                                weight: FontWeight.bold, 
                                spacing: 2,
                                // Text color logic
                                color: isDark ? CyberTheme.textMain : Colors.black))
                        ],
                      ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                      begin: 1.0,
                      end: 1.05,
                      duration: 1.5.seconds,
                      curve: Curves.easeInOut),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 9. LEADERBOARD
// ---------------------------------------------------------
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppBar(title: const Text("GLOBAL RANKING")),
      body: CyberBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('totalPoints', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final isMe = data['uid'] == myUid;
                return CyberCard(
                  borderColor: isMe ? CyberTheme.primary : Colors.grey.withOpacity(0.3),
                  isGlowing: isMe,
                  child: Row(
                    children: [
                      Text("#${index + 1}",
                          style: TextStyle(
                              color: index < 3
                                  ? CyberTheme.secondary
                                  : Colors.grey,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier')),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Text(
                              (data['displayName'] ?? "ANON").toUpperCase(),
                              style: CyberTheme.techText(color: textColor))),
                      Text("${data['totalPoints']} PTS",
                          style: CyberTheme.techText(
                              color: CyberTheme.primary,
                              weight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 10. PROFILE (MOVED TOGGLE TO APPBAR)
// ---------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MY PROFILE"),
        // --- MOVED TOGGLE HERE ---
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, child) {
              bool isLight = mode == ThemeMode.light;
              return Switch(
                value: isLight,
                activeThumbColor: Colors.black, // Dark switch for light mode
                inactiveThumbColor: CyberTheme.primary,
                inactiveTrackColor: Colors.black,
                onChanged: (val) {
                  themeNotifier.value = val ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: CyberBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: CyberTheme.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: CyberTheme.primary.withOpacity(0.4),
                              blurRadius: 20)
                        ]),
                    child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.black,
                        child: Text(data['displayName']?[0] ?? "U",
                            style: const TextStyle(
                                fontSize: 40, color: Colors.white))),
                  ),
                  const SizedBox(height: 24),
                  Text((data['displayName'] ?? "UNKNOWN").toUpperCase(),
                      style: CyberTheme.techText(size: 24, weight: FontWeight.bold, color: textColor)),
                  Text(user.email ?? "", style: CyberTheme.techText(color: Colors.grey)),
                  
                  // NOTE: Toggle switch removed from here as requested
                  
                  const SizedBox(height: 40),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: CyberButton(
                      text: "DISCONNECT (LOGOUT)",
                      color: Colors.red.shade900,
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 11. AR SCREEN
// ---------------------------------------------------------
class ArScreen extends StatefulWidget {
  final int score;
  const ArScreen({super.key, this.score = 50});
  @override
  State<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  @override
  Widget build(BuildContext context) {
    bool isDanger = widget.score > 60;
    Color hudColor = isDanger ? CyberTheme.danger : CyberTheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            "https://images.unsplash.com/photo-1518546305927-5a555bb7020d?q=80&w=1000&auto=format&fit=crop",
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.6),
            colorBlendMode: BlendMode.darken,
          ),
          // NOTE: GridPainter removed from AR view as well to be consistent
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: hudColor.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(140),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(color: hudColor.withOpacity(0.3), width: 5),
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 5.seconds),
                  ),
                  Center(child: Icon(Icons.add, color: hudColor, size: 40)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 60, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(color: Colors.white),
                Text("LIVE FEED // ANALYZING", style: CyberTheme.techText(color: hudColor, spacing: 2)),
                Icon(Icons.battery_charging_full, color: hudColor),
              ],
            ),
          ),
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: CyberCard(
              borderColor: hudColor,
              child: Column(
                children: [
                  Text(isDanger ? "WARNING: HIGH CARBON" : "STATUS: OPTIMAL",
                      style: CyberTheme.techText(color: hudColor, weight: FontWeight.bold, size: 18)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: widget.score / 100,
                    backgroundColor: Colors.black,
                    valueColor: AlwaysStoppedAnimation(hudColor),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}