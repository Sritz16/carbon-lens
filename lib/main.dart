import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/foundation.dart'; 
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

const String apiKey = "AIzaSyCZzIwka1DechHWODFT5kUU6JefTql5yO0";

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
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF121212);
  static const Color textMain = Color(0xFFE0E0E0);
  
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextMain = Color(0xFF1C1C1E);

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
          title: 'Carbon Lens',          
          themeMode: mode, 
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
// 2. BACKGROUND
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
// 3. UI WIDGETS
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
// 4. AUTH
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
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (!_isLogin && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("IDENTIFICATION REQUIRED. ENTER NAME."),
          backgroundColor: CyberTheme.danger));
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("INVALID EMAIL FORMAT. CHECK INPUT."),
          backgroundColor: CyberTheme.danger));
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("PASSWORD REQUIRED."),
          backgroundColor: CyberTheme.danger));
      return;
    }
    if (!_isLogin && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("PASSWORD TOO SHORT (MIN 6 CHARS)."),
          backgroundColor: CyberTheme.danger));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        UserCredential cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'uid': cred.user!.uid,
          'email': email,
          'displayName': name,
          'totalPoints': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      String customMessage = "ACCESS DENIED"; 
      switch (e.code) {
        case 'invalid-email': customMessage = "INVALID EMAIL SYNTAX."; break;
        case 'user-not-found':
        case 'invalid-credential': customMessage = "CREDENTIALS NOT FOUND."; break;
        case 'wrong-password': customMessage = "INCORRECT PASSWORD."; break;
        case 'email-already-in-use': customMessage = "ID ALREADY EXISTS."; break;
        case 'weak-password': customMessage = "PASSWORD TOO WEAK."; break;
        case 'network-request-failed': customMessage = "CONNECTION LOST."; break;
        default: customMessage = e.message ?? "AUTHENTICATION FAILED"; 
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(customMessage), backgroundColor: CyberTheme.danger));
    } catch (e) {
      print("Raw Error: $e"); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("SYSTEM MALFUNCTION. PLEASE RETRY."), 
          backgroundColor: CyberTheme.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5), 
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    .animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
                const SizedBox(height: 20),
                Text("CARBON LENS",
                    style: CyberTheme.techText(
                        size: 24, weight: FontWeight.bold, spacing: 4, color: CyberTheme.primary)),
                const SizedBox(height: 40),
                if (!_isLogin) _buildInput(_nameController, "AGENT NAME", Icons.badge),
                _buildInput(_emailController, "EMAIL ID", Icons.alternate_email),
                _buildInput(_passwordController, "PASSWORD", Icons.lock_outline, isPass: true),
                const SizedBox(height: 24),
                CyberButton(
                    text: _isLogin ? "LOG IN" : "SIGN UP",
                    onPressed: _submit,
                    isLoading: _isLoading),
                const SizedBox(height: 16),
                TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? "> Don't have an account? SIGN UP here" : "> Has access? LOG IN here",
                      style: CyberTheme.techText(color: Colors.grey, size: 12),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 5. MAIN SCREEN (MODIFIED WITH AR DOCK)
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
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Detect if Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, 
      body: Stack(
        fit: StackFit.expand,
        children: [
          _pages[_currentIndex],
          
          Positioned(
            bottom: 140, 
            right: 20,   
            child: ArFloatingDock(
              onActivate: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RealtimeScanner()));
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(
              color: isDark ? CyberTheme.primary.withOpacity(0.2) : Colors.black12
          )),
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.transparent,
          indicatorColor: CyberTheme.primary.withOpacity(isDark ? 0.2 : 0.3),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          
          destinations: [
            NavigationDestination(
                icon: Icon(Icons.grid_view, color: isDark ? Colors.grey : Colors.grey.shade600),
                selectedIcon: Icon(Icons.grid_view, 
                    color: isDark ? CyberTheme.primary : Colors.black), 
                label: "DASH"),
            NavigationDestination(
                icon: Icon(Icons.commute, color: isDark ? Colors.grey : Colors.grey.shade600),
                selectedIcon: Icon(Icons.commute,
                    color: isDark ? CyberTheme.primary : Colors.black), 
                label: "TRAVEL"),
            NavigationDestination(
                icon: Icon(Icons.center_focus_weak, color: isDark ? Colors.grey : Colors.grey.shade600),
                selectedIcon: Icon(Icons.center_focus_strong, 
                    color: isDark ? CyberTheme.primary : Colors.black), 
                label: "SCAN"),
            NavigationDestination(
                icon: Icon(Icons.emoji_events, color: isDark ? Colors.grey : Colors.grey.shade600),
                selectedIcon: Icon(Icons.emoji_events, 
                    color: isDark ? CyberTheme.primary : Colors.black), 
                label: "RANK"),
            NavigationDestination(
                icon: Icon(Icons.fingerprint, color: isDark ? Colors.grey : Colors.grey.shade600),
                selectedIcon: Icon(Icons.fingerprint, 
                    color: isDark ? CyberTheme.primary : Colors.black), 
                label: "ID"),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 6. DASHBOARD
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
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
                AppBar(
                  title: const Text("COMMAND CENTER"),
                  actions: [
                      ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeNotifier,
                      builder: (context, mode, child) {
                        bool isLight = mode == ThemeMode.light;
                        return IconButton(
                          icon: Icon(
                            isLight ? Icons.dark_mode : Icons.light_mode,
                            color: isLight ? Colors.black : CyberTheme.primary,
                          ),
                          onPressed: () {
                            themeNotifier.value = isLight ? ThemeMode.dark : ThemeMode.light;
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
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

                      final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                      int totalPoints = userData['totalPoints'] ?? 100; 

                      // LOCKDOWN LOGIC
                      bool isLocked = totalPoints < 20;

                      if (totalPoints <= 0) {
                        totalPoints = 0; 
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
                        progress = (totalPoints - prevGoal) / (nextGoal - prevGoal);
                      } else {
                        progress = 1.0;
                        pointsNeeded = 0;
                      }

                      return Column(
                        children: [
                          // ------------------------------------------
                          // 1. MAIN CARD (Clearance)
                          // ------------------------------------------
                          GestureDetector(
                            onTap: () => _showLevelMap(context, totalPoints, currentLevel),
                            child: CyberCard(
                              borderColor: isLocked ? CyberTheme.danger : CyberTheme.primary,
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
                                                  color: isLocked ? CyberTheme.danger : CyberTheme.primary)),
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
                                                color: isLocked ? CyberTheme.danger : CyberTheme.primary),
                                            borderRadius: BorderRadius.circular(4)),
                                        child: Text("$totalPoints PTS",
                                            style: CyberTheme.techText(
                                                color: isLocked ? CyberTheme.danger : CyberTheme.primary,
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
                                          gradient: LinearGradient(colors: [
                                            isLocked ? CyberTheme.danger : CyberTheme.primary,
                                            CyberTheme.secondary
                                          ]),
                                          boxShadow: [
                                            BoxShadow(
                                                color: (isLocked ? CyberTheme.danger : CyberTheme.primary)
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

                          // ------------------------------------------
                          // 2. RED WARNING BANNER
                          // ------------------------------------------
                          if (isLocked)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: CyberTheme.danger.withOpacity(0.2),
                                border: Border.all(color: CyberTheme.danger),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: CyberTheme.danger, size: 30),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("BUDGET LOCKDOWN ACTIVE", 
                                            style: CyberTheme.techText(color: CyberTheme.danger, weight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        const Text("Earn points to unlock scanner features.", 
                                            style: TextStyle(color: Colors.white70, fontSize: 10)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 500.ms),

                          // ------------------------------------------
                          // 3. RECENT LOGS HEADER
                          // ------------------------------------------
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text("> RECENT LOGS",
                                    style: CyberTheme.techText(
                                        size: 16, weight: FontWeight.bold, color: textColor))),
                          ),

                          // ------------------------------------------
                          // 4. LOGS LIST
                          // ------------------------------------------
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('scans')
                                  .where('userId', isEqualTo: user.uid)
                                  .orderBy('timestamp', descending: true) 
                                  .snapshots(),
                              builder: (context, scanSnap) {
                                if (!scanSnap.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final docs = scanSnap.data!.docs;
                                if (docs.isEmpty) {
                                  return Center(
                                      child: Text("NO DATA FOUND",
                                          style: CyberTheme.techText(color: Colors.grey)));
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 250),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final data = docs[index].data() as Map<String, dynamic>;
                                    int score = data['carbon_score'] ?? 0;
                                    Color scoreColor = score < 30
                                        ? CyberTheme.primary
                                        : (score < 70
                                            ? Colors.orange
                                            : CyberTheme.danger);
                                    Timestamp? t = data['timestamp'];
                                    DateTime date = t != null ? t.toDate() : DateTime.now();
                                    int? pImpact = data['points_impact'];
                                    String pText = "";
                                    Color pColor = Colors.grey;

                                    if (pImpact != null) {
                                      pText = pImpact > 0 ? "+$pImpact PTS" : "$pImpact PTS";
                                      pColor = pImpact > 0 ? CyberTheme.primary : CyberTheme.danger;
                                    } else {
                                      if (data['shadow_type'] != 'Travel') {
                                        pText = "-$score PTS"; 
                                        pColor = CyberTheme.danger;
                                      }
                                    }

                                    return CyberCard(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => DetailScreen(data: data))),
                                      borderColor: scoreColor,
                                      child: Row(
                                        children: [
                                          Icon(Icons.qr_code_2, color: scoreColor, size: 30),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // 1. Item Name
                                                Text(
                                                    (data['item_name'] ?? "UNKNOWN").toUpperCase(),
                                                    style: CyberTheme.techText(
                                                        weight: FontWeight.bold, color: textColor)),
                                                
                                                // 2. Time + Points
                                                Row(
                                                  children: [
                                                    Text(getTimeAgo(date),
                                                        style: CyberTheme.techText(
                                                            size: 10, color: Colors.grey)),
                                                    
                                                    if (pText.isNotEmpty) ...[
                                                      const SizedBox(width: 8),
                                                      Text(pText, 
                                                         style: CyberTheme.techText(
                                                            size: 10, 
                                                            color: pColor, 
                                                            weight: FontWeight.bold
                                                         )),
                                                    ]
                                                  ],
                                                ),
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
// 7. DETAIL SCREEN
// ---------------------------------------------------------
class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    int score = data['carbon_score'] ?? 0;
    Color color = score < 30 ? CyberTheme.primary : (score < 70 ? Colors.orange : CyberTheme.danger);
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
                    boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 40, spreadRadius: 10)],
                    gradient: RadialGradient(colors: [color.withOpacity(0.2), Colors.transparent]),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hub, size: 60, color: color).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
                      Text("$score", style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: color, fontFamily: 'Courier')),
                      Text("CARBON\nDENSITY", textAlign: TextAlign.center, style: CyberTheme.techText(size: 10, color: color)),
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
                    Builder(
                      builder: (context) {
                        if (data['shadow_type'] == 'Travel') return const SizedBox.shrink();

                        // 1. Try to get swaps from the API response
                        Map<String, dynamic>? swaps;
                        
                        if (data['smart_swaps'] != null) {
                           swaps = Map<String, dynamic>.from(data['smart_swaps']);
                        } else {
                           // Fallback to local engine
                           swaps = SwapEngine.getSwaps(data['item_name'] ?? ""); 
                        }

                        if (swaps == null) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("> INTELLIGENT ALTERNATIVES", style: CyberTheme.techText(color: CyberTheme.primary, weight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSwapCard("EASY", swaps['easy'] ?? "Reduce Usage", Colors.blue),
                                const SizedBox(width: 8),
                                _buildSwapCard("MED", swaps['medium'] ?? "Buy Used", Colors.orange),
                                const SizedBox(width: 8),
                                _buildSwapCard("HERO", swaps['hero'] ?? "Refuse Item", Colors.green),
                              ],
                            ),
                            const SizedBox(height: 30),
                          ],
                        );
                      }
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

  Widget _buildSwapCard(String level, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Text(level, style: CyberTheme.techText(size: 10, color: color, weight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: color.withOpacity(0.9), height: 1.2)),
          ],
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
          SizedBox(width: 100, child: Text(label, style: CyberTheme.techText(size: 12, color: Colors.grey))),
          Expanded(child: Text(value ?? "N/A", style: CyberTheme.techText(color: valColor ?? defaultColor))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 8. TRAVEL SCREEN
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

    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);
    
    // 1. Calculate Pollution (Visual Score)
    double myEmission = dist * (_emissionFactors[_selectedMode] ?? 0.0);
    int visualScore = (myEmission * 50).toInt().clamp(0, 100); 

    // 2. Calculate Points Impact (Reward vs Penalty)
    int pointsImpact = 0;
    
    if (_selectedMode == "Walk" || _selectedMode == "Bicycle") {
      pointsImpact = (dist * 20).toInt(); 
    } else if (_selectedMode == "Bus" || _selectedMode == "Train") {
      pointsImpact = (dist * 5).toInt();
    } else {
      pointsImpact = -(dist * 20).toInt(); 
    }
    
    pointsImpact = pointsImpact.clamp(-200, 200);

    // 3. Save to DB
    await FirebaseFirestore.instance.collection('scans').add({
      'item_name': "$_selectedMode Transport",
      'carbon_score': visualScore, 
      'shadow_type': "Travel",
      'nudge_text': "Mobility Log: $dist km via $_selectedMode",
      'tree_analogy': "Emission: ${myEmission.toStringAsFixed(2)} kg",
      'points_impact': pointsImpact, // 👈 Saves + or - based on mode
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 4. Update User Points
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'totalPoints': FieldValue.increment(pointsImpact)});

    if (mounted) {
      setState(() => _isSaving = false);
      _distanceController.clear();
      
      // Dynamic Message based on result
      String msg = pointsImpact >= 0 
          ? "TRIP LOGGED. +$pointsImpact PTS REWARD!" 
          : "HIGH CARBON TRIP. $pointsImpact PTS DEDUCTED.";
          
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: pointsImpact >= 0 ? CyberTheme.primary : CyberTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          // 🌟 RESTORED NEON BOX
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
                              color: isSelected
                                  ? (isDark ? CyberTheme.primary : Colors.black)
                                  : (isDark ? Colors.grey : Colors.grey.shade700),
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(mode.toUpperCase(),
                                style: TextStyle(
                                    color: isSelected
                                        ? (isDark ? CyberTheme.primary : Colors.black)
                                        : (isDark ? Colors.grey : Colors.grey.shade700),
                                    fontSize: 10,
                                    fontFamily: 'Courier'))
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),

                // Input Field Container
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
// 9. SCANNER
// ---------------------------------------------------------
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

String _cachedLocation = "Unknown Location";

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<String> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "Unknown Location";
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return "Unknown Location";
    }
    if (permission == LocationPermission.deniedForever) return "Unknown Location";
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.locality}, ${place.country}"; 
      }
    } catch (e) {
      print("Location Error: $e");
    }
    return "Unknown Location";
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((loc) {
      if(mounted) setState(() => _cachedLocation = loc);
    });
  }

  Future<void> _analyzeImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera, 
      maxWidth: 400, 
      maxHeight: 400, 
      imageQuality: 40
    );
    if (photo == null) return;

    setState(() => _isLoading = true);
    String userLocation = _cachedLocation; 

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
                  "text": "I am currently in $userLocation. Identify this object. "
                          "Estimate Carbon Footprint Score (0-100). "
                          "Provide 3 sustainable alternatives ('smart_swaps'): "
                          "1. Easy, 2. Medium, 3. Hero. "
                          "Return ONLY raw JSON (no markdown): {"
                          "  'item_name': 'String', "
                          "  'carbon_score': Int, "
                          "  'shadow_type': 'String', "
                          "  'nudge_text': 'String', "
                          "  'tree_analogy': 'String', "
                          "  'smart_swaps': {'easy': 'String', 'medium': 'String', 'hero': 'String'}"
                          "}"
                },
                {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}
              ]
            }]
          }));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String finalText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        
        int startIndex = finalText.indexOf('{');
        int endIndex = finalText.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1) {
          finalText = finalText.substring(startIndex, endIndex + 1);
        }

        final Map<String, dynamic> parsedData = jsonDecode(finalText);
        
        int aiScore = parsedData['carbon_score'] ?? 50; 
        int variation = Random().nextInt(6) - 3; 
        int finalScore = (aiScore + variation).clamp(0, 100);

        parsedData['carbon_score'] = finalScore;

        // 👇 NEW LOGIC: PIVOT SYSTEM
        int pointsImpact = (50 - finalScore) * 2; 

        if (mounted) {
           setState(() => _isLoading = false);
           Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(data: parsedData)));
        }

        // Save to DB
        await FirebaseFirestore.instance.collection('scans').add({
          ...parsedData,
          'points_impact': pointsImpact,
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp()
        });

        // Update Wallet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'totalPoints': FieldValue.increment(pointsImpact)});
            
      } else {
        throw "API Error: ${response.statusCode}";
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analysis Failed. Check Console.")));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Text("ANALYZING MATTER...", style: CyberTheme.techText(color: CyberTheme.primary))
                  ],
                )
              : GestureDetector(
                  onTap: _analyzeImage,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.black.withOpacity(0.5) : Colors.white,
                      border: Border.all(color: isDark ? CyberTheme.primary : Colors.black, width: 2),
                      boxShadow: [BoxShadow(color: isDark ? CyberTheme.primary.withOpacity(0.3) : Colors.black12, blurRadius: 30, spreadRadius: 5)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 90, color: isDark ? Colors.white : Colors.black), 
                        const SizedBox(height: 10),
                        Text("INITIATE SCAN", style: CyberTheme.techText(weight: FontWeight.bold, spacing: 2, color: isDark ? CyberTheme.textMain : Colors.black))
                        ],
                      ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.05, duration: 1.5.seconds, curve: Curves.easeInOut),
                ),
        ),
      ),
    );
  }
}

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
                return CyberCard(
                  borderColor: isMe ? CyberTheme.primary : Colors.grey.withOpacity(0.3),
                  isGlowing: isMe,
                  child: Row(
                    children: [
                      Text("#${index + 1}", style: TextStyle(color: index < 3 ? CyberTheme.secondary : Colors.grey, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                      const SizedBox(width: 16),
                      Expanded(child: Text((data['displayName'] ?? "ANON").toUpperCase(), style: CyberTheme.techText(color: textColor))),
                      Text("${data['totalPoints']} PTS", style: CyberTheme.techText(color: CyberTheme.primary, weight: FontWeight.bold)),
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("MY PROFILE")),
      body: CyberBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: CyberTheme.primary, width: 2), boxShadow: [BoxShadow(color: CyberTheme.primary.withOpacity(0.4), blurRadius: 20)]),
                    child: CircleAvatar(radius: 50, backgroundColor: Colors.black, child: Text(data['displayName']?[0] ?? "U", style: const TextStyle(fontSize: 40, color: Colors.white))),
                  ),
                  const SizedBox(height: 24),
                  Text((data['displayName'] ?? "UNKNOWN").toUpperCase(), style: CyberTheme.techText(size: 24, weight: FontWeight.bold, color: textColor)),
                  Text(user.email ?? "", style: CyberTheme.techText(color: isDark ? Colors.grey : Colors.black87)),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: CyberButton(text: "DISCONNECT (LOGOUT)", color: Colors.red.shade900, onPressed: () => FirebaseAuth.instance.signOut()),
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

class SwapEngine {
  static Map<String, String>? getSwaps(String itemName) {
    String name = itemName.toLowerCase();
    if (name.contains('burger') || name.contains('meat') || name.contains('beef')) {
      return {'easy': 'Chicken Burger', 'medium': 'Veg Patty', 'hero': 'Lentil Burger'};
    }
    if (name.contains('car') || name.contains('vehicle')) {
      return {'easy': 'Carpooling', 'medium': 'Public Bus', 'hero': 'Bicycle'};
    }
    if (name.contains('plastic') || name.contains('bottle')) {
      return {'easy': 'Recycle Bin', 'medium': 'Reuse Bottle', 'hero': 'Metal Flask'};
    }
    return {'easy': 'Extend Use', 'medium': 'Buy Used', 'hero': 'Refuse Item'};
  }
}
// ---------------------------------------------------------
// 10. CUSTOM AR DOCK BUTTON (Crash-Proof Version)
// ---------------------------------------------------------
class ArFloatingDock extends StatefulWidget {
  final VoidCallback onActivate;
  const ArFloatingDock({super.key, required this.onActivate});

  @override
  State<ArFloatingDock> createState() => _ArFloatingDockState();
}

class _ArFloatingDockState extends State<ArFloatingDock> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isActivating = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = CyberTheme.secondary;
    
    // Logic: Collapse text if Activating.
    // On Mobile (!kIsWeb), we default to expanded unless activating.
    bool showExpanded = (kIsWeb ? _isHovered : true) && !_isActivating;
    
    // Width: 60 (Circle) or 150 (Pill)
    double targetWidth = _isActivating ? 60 : (showExpanded ? 150 : 60);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          if (_isActivating) return;
          _pulseController.stop();
          setState(() => _isActivating = true); // Shrink immediately
          
          // Wait for the "Shake" animation
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted) {
            widget.onActivate();
            // Reset after navigation
            setState(() => _isActivating = false);
            if (!kIsWeb) _pulseController.repeat(reverse: true);
          }
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            // Breathing effect (only when idle)
            double scale = (!kIsWeb && !_isActivating) 
                ? (1.0 + (_pulseController.value * 0.05)) 
                : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: ClipRRect( 
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter( 
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                height: 60,
                width: targetWidth,
                decoration: BoxDecoration(
                  // Glassmorphism
                  color: color.withOpacity(_isHovered || !kIsWeb ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: color.withOpacity(0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3), 
                      blurRadius: 20,
                      spreadRadius: -5,
                    )
                  ],
                ),
                // 🛠️ FIX: Wrap content in SingleChildScrollView to prevent Overflow
                child: _isActivating
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(), 
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.view_in_ar, color: Colors.white, size: 28)
                                  .animate(target: showExpanded ? 1 : 0)
                                  .scaleXY(end: 1.1, duration: 300.ms),
                              
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: SizedBox(
                                  width: showExpanded ? 80 : 0,
                                  child: showExpanded
                                      ? Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Text(
                                            "AR SCAN",
                                            overflow: TextOverflow.visible,
                                            softWrap: false,
                                            style: CyberTheme.techText(
                                              color: Colors.white,
                                              weight: FontWeight.bold,
                                              spacing: 1.2,
                                            ),
                                          ).animate().fadeIn(delay: 100.ms).slideX(),
                                        )
                                      : const SizedBox(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ).animate(target: _isActivating ? 1 : 0)
           .shake(hz: 10, curve: Curves.easeInOut)
           .then(delay: 1000.ms)
           .scaleXY(end: 25, duration: 400.ms, curve: Curves.easeIn),
        ),
      ),
    );
  }
}