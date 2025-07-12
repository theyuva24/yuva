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
        // Ensure user is authenticated (anonymous for now)
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              'YUVA',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
