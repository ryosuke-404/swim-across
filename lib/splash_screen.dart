import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_trip/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnimation;
  late Animation<double> _bubbleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(); // Repeat for continuous effect

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _bubbleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.linear),
      ),
    );

    _checkOnboardingStatus();
  }

  void _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.stop(); // Stop animation before navigating
        if (seenOnboarding) {
          Navigator.pushReplacementNamed(context, '/menu');
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade200, Colors.blue.shade700],
          ),
        ),
        child: Stack(
          children: [
            // Ripples
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RipplePainter(
                    animationValue: _rippleAnimation.value,
                  ),
                  child: Container(),
                );
              },
            ),
            // Bubbles
            AnimatedBuilder(
              animation: _bubbleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BubblePainter(
                    animationValue: _bubbleAnimation.value,
                    canvasSize: MediaQuery.of(context).size,
                  ),
                  child: Container(),
                );
              },
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo (Rounded)
                  ClipOval(
                    child: Image.asset(
                      'assets/icon.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit
                          .cover, // Ensure the image covers the circular area
                    ),
                  ),
                  const SizedBox(height: 20),
                  // App Title
                  const Text(
                    "Swim Across",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double animationValue;

  _RipplePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3 * (1 - animationValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3 * animationValue;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _BubblePainter extends CustomPainter {
  final double animationValue;
  final Size canvasSize;

  _BubblePainter({required this.animationValue, required this.canvasSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5 * (1 - animationValue))
      ..style = PaintingStyle.fill;

    // Draw bubbles across the entire screen
    final random = Random(
      0,
    ); // Use a fixed seed for consistent bubble positions per animation cycle
    for (int i = 0; i < 20; i++) {
      // Increased number of bubbles
      final x = random.nextDouble() * size.width; // Random X across the screen
      final y = canvasSize.height * (1 - animationValue) +
          (i * 50) -
          (random.nextDouble() * 100); // Bubbles rise from bottom
      final radius = 2.0 + (random.nextDouble() * 3); // Random bubble size

      if (y > -radius && y < canvasSize.height + radius) {
        // Only draw if visible
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.canvasSize != canvasSize;
  }
}
