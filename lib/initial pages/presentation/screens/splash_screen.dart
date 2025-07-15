import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding_screen.dart';
import '../../../../Home screen/home_screen.dart';
import '../../../../core/services/auth_service.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!context.mounted) return;

      try {
        final authService = AuthService();

        debugPrint('SplashScreen: Starting authentication check');
        authService.debugAuthState();

        // Check if user is fully registered (authenticated + has data in Firestore)
        final isFullyRegistered = await authService.isUserFullyRegistered();

        debugPrint('SplashScreen: isFullyRegistered = $isFullyRegistered');

        if (!context.mounted) return;

        if (isFullyRegistered) {
          debugPrint('SplashScreen: Navigating to HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          debugPrint('SplashScreen: Navigating to OnboardingScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      } catch (e) {
        debugPrint('SplashScreen: Error during authentication: $e');
        // If authentication fails, still navigate to onboarding
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF181C23),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _NeonLinesPainter())),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F6FF).withOpacity(0.7),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF00F6FF),
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFF00F6FF),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'YUVA',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00F6FF),
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        blurRadius: 32,
                        color: const Color(0xFF00F6FF),
                        offset: Offset(0, 0),
                      ),
                      Shadow(
                        blurRadius: 8,
                        color: const Color(0xFF00F6FF),
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Neon lines painter (reuse from OTP screen)
class _NeonLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintCyan =
        Paint()
          ..color = const Color(0xFF00F6FF).withOpacity(0.7)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final paintMagenta =
        Paint()
          ..color = const Color(0xFFFF00E0).withOpacity(0.7)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    // Top left curve
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(-40, -40), radius: 160),
      0.2,
      1.5,
      false,
      paintCyan,
    );
    // Bottom left curve
    canvas.drawArc(
      Rect.fromCircle(center: Offset(-60, size.height + 60), radius: 180),
      3.8,
      1.5,
      false,
      paintCyan,
    );
    // Top right magenta
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width + 40, 0), radius: 140),
      3.5,
      1.2,
      false,
      paintMagenta,
    );
    // Bottom right magenta
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width + 60, size.height + 60),
        radius: 180,
      ),
      3.8,
      1.5,
      false,
      paintMagenta,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
