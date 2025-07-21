import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding_screen.dart';
import '../../../universal/screens/home_screen.dart';
import '../../auth_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../universal/theme/app_theme.dart';

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
      backgroundColor: AppThemeLight.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppThemeLight.primary.withAlpha(51),
                    blurRadius: 32.r,
                    spreadRadius: 8.r,
                  ),
                ],
                border: Border.all(color: AppThemeLight.primary, width: 4.w),
              ),
              child: Icon(
                Icons.school,
                color: AppThemeLight.primary,
                size: 64.sp,
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'YUVA',
              style: TextStyle(
                fontSize: 48.sp,
                fontWeight: FontWeight.bold,
                color: AppThemeLight.primary,
                letterSpacing: 4.w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
